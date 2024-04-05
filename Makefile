all: build

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""
	@echo "   1. make build     - build the nerd-fonts-patcher image"
	@echo "   2. make release   - build the nerd-fonts-patcher image with the version tag"
	@echo "   3. make patch     - patch monospace fonts inside '$(shell pwd)/in' directory with the complete set of glyphs"

build:
	@docker build --tag=cdalvaro/docker-nerd-fonts-patcher:latest .

release: build
	@docker tag cdalvaro/docker-nerd-fonts-patcher:latest \
		cdalvaro/docker-nerd-fonts-patcher:$(shell cat VERSION) .

patch:
	@docker run --rm \
		--volume $(shell pwd)/in:/input \
    --volume $(shell pwd)/out:/output \
		--user $(shell id -u):$(shell id -g) \
		-- \
    cdalvaro/docker-nerd-fonts-patcher:latest \
		  --quiet --no-progressbars \
		  --complete --careful
