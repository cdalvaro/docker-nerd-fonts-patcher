# Nerd Fonts Patcher v2.1.0

Dockerfile to build a Nerd Fonts Patcher image for the Docker opensource container platform.

[**Nerd Fonts**](https://www.nerdfonts.com) is a project that patches developer targeted fonts with a high number of glyphs (icons).
Specifically to add a high number of extra glyphs from popular 'iconic fonts' such as
[Font Awesome ➶][font-awesome], [Devicons ➶][vorillaz-devicons] and [Octicons ➶][octicons].

<p align="center">
  <a href="https://github.com/ryanoasis/nerd-fonts">
    <img src="https://www.nerdfonts.com/assets/img/sankey-glyphs-combined-diagram.png" alt="Nerd Fonts Sankey Diagram">
  </a>
</p>

## Patch Your Own Font

Just copy all your fonts you want to patch into `$(pwd)/in` directory and execute the following command:

```sh
docker run --rm \
    --volume $(pwd)/in:/nerd-fonts/in:ro \
    --volume $(pwd)/out:/nerd-fonts/out \
    --user $(id -u):$(id -g) \
    cdalvaro/nerd-fonts-patcher:2.1.0 \
    --quiet --no-progressbars \
    --mono --adjust-line-height --complete --careful
```

The container will patch all files with extensions `.otf` and `.ttf` inside `$(pwd)/in` and
leave them into `$(pwd)/out`.

More information is available at the [official documentation][patch-your-own-font] site.

## Available Sources

This image can be downloaded from [Dockerhub](https://hub.docker.com/r/cdalvaro/nerd-fonts-patcher/)

```sh
docker pull cdalvaro/nerd-fonts-patcher:latest
```

or from [Quay.io](https://quay.io/repository/cdalvaro/nerd-fonts-patcher) too.

```sh
docker pull quay.io/cdalvaro/nerd-fonts-patcher
```

[vorillaz-devicons]:https://vorillaz.github.io/devicons/
[font-awesome]:https://github.com/FortAwesome/Font-Awesome
[octicons]:https://github.com/primer/octicons
[patch-your-own-font]:https://github.com/ryanoasis/nerd-fonts/blob/master/readme.md#option-8-patch-your-own-font
