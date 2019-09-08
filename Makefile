all: build

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""
	@echo "   1. make build     - build the nerd-fonts-patcher image"
	@echo "   2. make release   - build the nerd-fonts-patcher image with the version tag"
	@echo "   3. make patch     - patch monospace fonts inside $(shell pwd)/in directory with the complete set of glyphs"

build:
	@docker build --tag=cdalvaro/nerd-fonts-patcher .

release: build
	@docker build --tag=cdalvaro/nerd-fonts-patcher:$(shell cat VERSION) .

patch:
	@docker run --rm \
		--volume $(shell pwd)/in:/nerd-fonts/in:ro \
    	--volume $(shell pwd)/out:/nerd-fonts/out \
		--user $(shell id -u):$(shell id -g) \
    	cdalvaro/nerd-fonts-patcher:latest \
		--quiet --no-progressbars \
		--mono --adjust-line-height --complete --careful
