[![Nerd Fonts][nerdfonts_badge]][nerdfonts_release_notes]
[![Ubuntu Image][ubuntu_badge]][ubuntu_hub_docker]
[![Publish Workflow][github_publish_badge]][github_publish_workflow]

[![Docker Image Size][docker_size_badge]][docker_hub_tags]
[![Architecture AMD64][arch_amd64_badge]][arch_link]
[![Architecture ARM64][arch_arm64_badge]][arch_link]
[![Architecture ARM/v7][arch_arm_badge]][arch_link]

# Dockerized Nerd Fonts Patcher v2.3.1

Dockerfile to build a Nerd Fonts Patcher image for the Docker opensource container platform.

[**Nerd Fonts**](https://www.nerdfonts.com) is a project that patches developer targeted fonts with a high number of
glyphs (icons).
Specifically to add a high number of extra glyphs from popular 'iconic fonts' such as
[Font Awesome ➶][font-awesome], [Devicons ➶][vorillaz-devicons] and [Octicons ➶][octicons].

<div style="alignment: center">
  <a href="https://github.com/ryanoasis/nerd-fonts">
    <img src="https://www.nerdfonts.com/assets/img/sankey-glyphs-combined-diagram.png" alt="Nerd Fonts Sankey Diagram">
  </a>
</div>

## Patch Your Own Font

Just copy all your fonts you want to patch into `$(pwd)/in` directory and execute the following command:

```sh
docker run --rm \
    --volume $(pwd)/in:/nerd-fonts/in \
    --volume $(pwd)/out:/nerd-fonts/out \
    --user $(id -u):$(id -g) \
    ghcr.io/cdalvaro/docker-nerd-fonts-patcher:latest \
    --quiet --no-progressbars \
    --mono --adjust-line-height --complete --careful
```

The container will patch all files with extensions `.otf` and `.ttf` inside `$(pwd)/in` and
leave them into `$(pwd)/out`.

More information is available at the [official documentation][patch-your-own-font] site.

## Available Sources

This image can be downloaded from [Dockerhub](https://hub.docker.com/r/cdalvaro/docker-nerd-fonts-patcher/)

```sh
docker pull cdalvaro/docker-nerd-fonts-patcher:latest
```

from [Quay.io](https://quay.io/repository/cdalvaro/docker-nerd-fonts-patcher) too.

```sh
docker pull quay.io/cdalvaro/docker-nerd-fonts-patcher
```

or from [GitHub Container Registry](https://ghcr.io/cdalvaro/docker-nerd-fonts-patcher) too.

```sh
docker pull ghcr.io/cdalvaro/docker-nerd-fonts-patcher
```

[nerdfonts_badge]: https://img.shields.io/badge/Nerd%20Fonts-v2.3.1-lightgrey.svg

[nerdfonts_release_notes]: https://github.com/ryanoasis/nerd-fonts/releases/tag/v2.3.1 "Nerd Fonts Release Notes"

[ubuntu_badge]: https://img.shields.io/badge/ubuntu-jammy--20221130-E95420.svg?logo=Ubuntu

[ubuntu_hub_docker]: https://hub.docker.com/_/ubuntu/ "Ubuntu Image"

[github_publish_badge]: https://github.com/cdalvaro/docker-nerd-fonts-patcher/actions/workflows/publish.yml/badge.svg

[github_publish_workflow]: https://github.com/cdalvaro/docker-nerd-fonts-patcher/actions/workflows/publish.yml

[docker_size_badge]: https://img.shields.io/docker/image-size/cdalvaro/docker-nerd-fonts-patcher/latest?logo=docker&color=2496ED

[docker_hub_tags]: https://hub.docker.com/repository/docker/cdalvaro/docker-nerd-fonts-patcher/tags

[arch_amd64_badge]: https://img.shields.io/badge/arch-amd64-inactive.svg

[arch_arm_badge]: https://img.shields.io/badge/arch-arm/v7-inactive.svg

[arch_arm64_badge]: https://img.shields.io/badge/arch-arm64-inactive.svg

[arch_link]: https://github.com/users/cdalvaro/packages/container/package/docker-nerd-fonts-patcher

[vorillaz-devicons]:https://vorillaz.github.io/devicons/

[font-awesome]:https://github.com/FortAwesome/Font-Awesome

[octicons]:https://github.com/primer/octicons

[patch-your-own-font]:https://github.com/ryanoasis/nerd-fonts/blob/master/readme.md#option-8-patch-your-own-font
