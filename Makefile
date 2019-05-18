.DEFAULT_GOAL := help

build: ## Make the docker image
	docker build -t halkeye/cups-gcp .

run: ## Run the docker image
	docker run -it --rm --name cups -p 631:631 -v "$$(realpath config):/config" halkeye/cups-gcp

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-.]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'


