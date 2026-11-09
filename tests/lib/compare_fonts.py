#!/usr/bin/env python3
"""Compare a directory of patched fonts against a directory of reference fonts.

Usage:
    compare_fonts.py EXPECTED_DIR ACTUAL_DIR [--max-items N]

For every font in EXPECTED_DIR (``*.ttf``/``*.otf``) a font with the same file
name must exist in ACTUAL_DIR, and vice versa. Each pair is compared in three
stages, from cheapest to most detailed:

1. Byte identity (SHA-256). This is the expected outcome when the patcher runs
   with the same FontForge build and SOURCE_DATE_EPOCH as the reference fonts.
2. Table by table, on the raw table bytes. Only ``head.modified`` and
   ``head.checkSumAdjustment`` are ignored: they depend on the build time,
   not on the patching itself.
3. For each table that differs, a readable report: changed name records,
   remapped code points, renamed glyphs, changed outlines or metrics, changed
   header fields, or a short TTX diff for any other table.

Exit status: 0 if all fonts are equivalent, 1 otherwise, 2 on usage errors.
"""

import argparse
import difflib
import hashlib
import io
import sys
from pathlib import Path

from fontTools.pens.recordingPen import DecomposingRecordingPen
from fontTools.ttLib import TTFont

FONT_SUFFIXES = {".ttf", ".otf"}

# Fields that change with the build time but not with the patching. They are
# the only differences that are tolerated.
IGNORED_FIELDS = {"head": {"modified", "checkSumAdjustment"}}


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def font_files(directory):
    return {p.name: p for p in directory.iterdir() if p.suffix.lower() in FONT_SUFFIXES}


def clip(items, max_items):
    """Return at most max_items lines, plus a line saying how many were left out."""
    items = list(items)
    if len(items) <= max_items:
        return items
    return items[:max_items] + [f"... ({len(items) - max_items} more)"]


# --- Per-table reporters -----------------------------------------------------
# Each one receives both fonts and returns a list of human-readable differences.
# An empty list means "no meaningful difference" for that table.


def diff_fields(table_tag, expected, actual):
    """Compare the decompiled attributes of a simple table (head, hhea, OS/2...)."""
    ignored = IGNORED_FIELDS.get(table_tag, set())
    exp, act = vars(expected[table_tag]), vars(actual[table_tag])
    lines = []
    for field in sorted(set(exp) | set(act)):
        if field in ignored or field.startswith("_") or field == "tableTag":
            continue
        if exp.get(field) != act.get(field):
            lines.append(f"{field}: {exp.get(field)!r} -> {act.get(field)!r}")
    return lines


def diff_name(expected, actual):
    def records(font):
        return {
            (r.nameID, r.platformID, r.platEncID, r.langID): r.toUnicode()
            for r in font["name"].names
        }

    exp, act = records(expected), records(actual)
    lines = []
    for key in sorted(set(exp) | set(act)):
        if exp.get(key) != act.get(key):
            name_id, platform_id = key[0], key[1]
            lines.append(
                f"nameID {name_id} (platform {platform_id}): "
                f"{exp.get(key)!r} -> {act.get(key)!r}"
            )
    return lines


def diff_cmap(expected, actual):
    exp, act = expected.getBestCmap(), actual.getBestCmap()
    lines = []
    for cp in sorted(set(exp) | set(act)):
        if exp.get(cp) != act.get(cp):
            lines.append(f"U+{cp:04X}: {exp.get(cp)} -> {act.get(cp)}")
    # Same best cmap but different raw bytes: the subtable layout changed.
    if not lines:
        lines.append("Same mapping, different subtables/encoding")
    return lines


def diff_glyph_order(expected, actual):
    exp, act = expected.getGlyphOrder(), actual.getGlyphOrder()
    lines = []
    if len(exp) != len(act):
        lines.append(f"glyph count: {len(exp)} -> {len(act)}")
    for gid, (e, a) in enumerate(zip(exp, act)):
        if e != a:
            lines.append(f"gid {gid}: {e} -> {a}")
    return lines


def diff_post(expected, actual):
    # Glyph names live in 'post' (format 2), so that is where renames show up.
    lines = diff_glyph_order(expected, actual)
    header = [
        line
        for line in diff_fields("post", expected, actual)
        if not line.startswith(("extraNames", "mapping", "glyphOrder", "data"))
    ]
    return header + lines


def diff_outlines(expected, actual):
    exp_set, act_set = expected.getGlyphSet(), actual.getGlyphSet()
    common = [g for g in expected.getGlyphOrder() if g in act_set]
    lines = []
    for name in common:
        pens = []
        for glyph_set in (exp_set, act_set):
            pen = DecomposingRecordingPen(glyph_set)
            glyph_set[name].draw(pen)
            pens.append(pen.value)
        if pens[0] != pens[1]:
            lines.append(f"outline of {name!r} differs")
    if not lines:
        # Outlines are the same, so the difference is in hinting/instructions
        # or in how the table is encoded.
        lines.append("Same outlines, different hinting or encoding")
    return lines


def diff_hmtx(expected, actual):
    exp, act = expected["hmtx"].metrics, actual["hmtx"].metrics
    lines = []
    for name in expected.getGlyphOrder():
        if name in act and exp[name] != act[name]:
            lines.append(f"{name}: (advance, lsb) {exp[name]} -> {act[name]}")
    return lines


def diff_ttx(table_tag, expected, actual):
    """Fallback for complex tables (GSUB, GPOS...): unified diff of their TTX dump."""

    def dump(font):
        buffer = io.StringIO()
        font.saveXML(buffer, tables=[table_tag])
        return buffer.getvalue().splitlines()[2:]  # skip the header with the version

    diff = difflib.unified_diff(dump(expected), dump(actual), "expected", "actual", lineterm="", n=1)
    return list(diff)[2:]  # skip the ---/+++ header


REPORTERS = {
    "name": diff_name,
    "cmap": diff_cmap,
    "post": diff_post,
    "glyf": diff_outlines,
    "CFF ": diff_outlines,
    "hmtx": diff_hmtx,
}
FIELD_TABLES = {"head", "hhea", "maxp", "OS/2", "vhea"}


def compare_fonts(expected_path, actual_path):
    """Return a dict {table: [differences]}; empty if the fonts are equivalent."""
    expected, actual = TTFont(expected_path), TTFont(actual_path)
    problems = {}

    exp_tags, act_tags = set(expected.keys()), set(actual.keys())
    exp_tags.discard("GlyphOrder")
    act_tags.discard("GlyphOrder")
    if exp_tags - act_tags:
        problems["(tables)"] = [f"missing tables: {sorted(exp_tags - act_tags)}"]
    if act_tags - exp_tags:
        problems.setdefault("(tables)", []).append(f"extra tables: {sorted(act_tags - exp_tags)}")

    for tag in sorted(exp_tags & act_tags):
        # Raw bytes first: cheap and exact. 'head' always differs in raw bytes
        # when the timestamps differ, so it is checked field by field.
        if tag != "head" and expected.reader[tag] == actual.reader[tag]:
            continue
        if tag in REPORTERS:
            lines = REPORTERS[tag](expected, actual)
        elif tag in FIELD_TABLES:
            lines = diff_fields(tag, expected, actual)
        else:
            lines = diff_ttx(tag, expected, actual)
        if lines:
            problems[tag] = lines
    return problems


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("expected_dir", type=Path, help="Directory with the reference fonts")
    parser.add_argument("actual_dir", type=Path, help="Directory with the fonts under test")
    parser.add_argument("--max-items", type=int, default=10, help="Differences shown per table (default: 10)")
    args = parser.parse_args()

    for directory in (args.expected_dir, args.actual_dir):
        if not directory.is_dir():
            parser.error(f"not a directory: {directory}")

    expected, actual = font_files(args.expected_dir), font_files(args.actual_dir)
    if not expected:
        parser.error(f"no fonts found in {args.expected_dir}")

    failed = False
    for name in sorted(set(expected) - set(actual)):
        print(f"🔥 {name}: not generated")
        failed = True
    for name in sorted(set(actual) - set(expected)):
        print(f"🔥 {name}: generated but not in the reference set")
        failed = True

    for name in sorted(set(expected) & set(actual)):
        if sha256(expected[name]) == sha256(actual[name]):
            print(f"✅ {name}: identical")
            continue
        problems = compare_fonts(expected[name], actual[name])
        if not problems:
            print(f"✅ {name}: equivalent (only build timestamps differ)")
            continue
        failed = True
        print(f"🔥 {name}: differs in {', '.join(problems)}")
        for tag, lines in problems.items():
            print(f"   [{tag}]")
            for line in clip(lines, args.max_items):
                print(f"     {line}")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
