# Check if Docker is installed
DOCKER := $(shell command -v docker 2> /dev/null)

# Check if Podman is installed
PODMAN := $(shell command -v podman 2> /dev/null)

# If neither Docker nor Podman is installed, exit with an error
ifeq (,$(or $(DOCKER),$(PODMAN)))
$(error "Neither Docker nor Podman is installed.")
endif

# If Podman is installed, use it instead of Docker
ifdef PODMAN
CONTAINER_ENGINE := podman
else
CONTAINER_ENGINE := docker
endif

.PHONY: help build release patch

all: build

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""
	@echo "   1. make build     - build the nerd-fonts-patcher image"
	@echo "   2. make release   - build the nerd-fonts-patcher image with the version tag"
	@echo "   3. make patch     - patch monospace fonts inside '$(shell pwd)/in' directory with the complete set of glyphs"

build:
	$(CONTAINER_ENGINE) build --tag=ghcr.io/cdalvaro/docker-nerd-fonts-patcher:latest .

release: build
	$(CONTAINER_ENGINE) tag ghcr.io/cdalvaro/docker-nerd-fonts-patcher:latest \
		ghcr.io/cdalvaro/docker-nerd-fonts-patcher:$(shell cat VERSION) .

patch:
	$(CONTAINER_ENGINE) run -it --rm \
		--volume $(shell pwd)/in:/input \
		--volume $(shell pwd)/out:/output \
		--user $(shell id -u):$(shell id -g) \
		-- \
		ghcr.io/cdalvaro/docker-nerd-fonts-patcher:latest \
			--quiet --no-progressbars --complete
