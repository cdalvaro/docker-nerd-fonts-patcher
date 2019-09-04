#!/bin/bash

set -e

options="$@"
# TODO: Parse options in order to remove -out --outputdir
# TODO: If -v, --version or -h, --help is asked launch only once and exit

# Get fonts available in directory ${INPUT_DIR}/
fonts=( $(find ${INPUT_DIR}/ -iregex '.*\.\(otf\|ttf\)$' 2>/dev/null) )

# Check whether there are fonts to patch
if [ ${#fonts[@]} -eq 0 ]; then
    (2> echo -e "\e[1;31mError\e[0m: There are no \e[0;32m.otf\e[0m neither \e[0;32m.ttf\e[0m fonts inside \e[0;33m${INPUT_DIR}/\e[0m directory")
    exit 1
fi

# Patch fonts
for font in "${fonts[@]}"; do
    echo -e "\e[0;33m==>\e[0m \e[0;33mPatching font\e[0m \e[0;32m${font}\e[0m ..."
    fontforge -script font-patcher -out ${OUTPUT_DIR}/ ${options[@]} "${font}"
done

exit 0
