# Default Shell
SHELL				= /bin/bash
PROJECTDIR			= $(CURDIR)
COMMIT				= $(shell git rev-parse --short HEAD)
THIS 				:= $(lastword $(MAKEFILE_LIST))
MAKEFLAGS 			+= --no-print-directory

################################################################################
# Include Makefiles
include $(PROJECTDIR)/Makefile.help

################################################################################
# Build variables
MDB_VERSION			:= $(or ${MDB_VERSION},latest)
DOCKER_FILE			:= $(or ${DOCKER_FILE},Dockerfile.50)
DOCKER_IMAGE		:= $(or ${DOCKER_IMAGE},mongo:$(MDB_VERSION))
BUILD_DATE			:= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
CI_PROJECT_URL		:= $(or ${CI_PROJECT_URL},$(shell echo $$(git config --get remote.origin.url | sed 's/....$$//')))
CI_COMMIT_SHORT_SHA	:= $(or ${CI_COMMIT_SHORT_SHA},$(shell git rev-parse --short HEAD))

################################################################################
# Run variables
PUID 				:= $(or ${PUID},1000)
PGID 				:= $(or ${PGID},100)
DATA_DIR 			:= $(or ${DATA_DIR},$(CURDIR)/data)
TZ					:= $(or ${TZ},Europe/London)
DOCKER_NAME			:= $(or ${DOCKER_NAME},mongo-test-$(MDB_VERSION))
DOCKER_HOSTNAME		:= $(or ${DOCKER_HOSTNAME},mongo)

################################################################################
build-vars: ## Show build variables
	@echo "Mongo Version: $(MDB_VERSION)"
	@echo "Docker:"
	@echo "  File:        $(DOCKER_FILE)"
	@echo "  Tag:         $(DOCKER_IMAGE)"

build: build-vars ## Build
	@echo "Building Mongo"
	@docker build \
		--pull \
		--build-arg DOCKER_IMAGE="$(DOCKER_IMAGE)" \
		--build-arg BUILD_DATE="$(BUILD_DATE)" \
		--build-arg VCS_REF="$(CI_COMMIT_SHORT_SHA)" \
		--build-arg CI_PROJECT_URL="$(CI_PROJECT_URL)" \
		--build-arg CI_PROJECT_NAME="mongo" \
		--file=$(DOCKER_FILE) \
		--tag $(DOCKER_IMAGE) .

push: ## Push container to registry
	@echo "Pushing container to registry: $(DOCKER_IMAGE)"
	@docker push $(DOCKER_IMAGE)

inspect: ## Inspect container
	@echo "Inspecting container: $(DOCKER_IMAGE)"
	@docker inspect $(DOCKER_IMAGE)

clean: ## Clean data directory
	@echo "Cleaning data directory"
	@rm -rf $(CURDIR)/data/*

run: ## Run
	@mkdir -p $(CURDIR)/data
	@docker run \
		--rm \
		--interactive \
		--tty \
		--name $(DOCKER_NAME) \
		--hostname $(DOCKER_HOSTNAME) \
		-e TZ=$(TZ) \
		-e PUID=$(PUID) \
		-e PGID=$(PGID) \
		-v $(DATA_DIR):/config \
		$(DOCKER_IMAGE)

shell: ## Shell
	@docker exec -it $(DOCKER_NAME) bash

health: ## Healthcheck
	@docker inspect --format='{{json .State.Health}}' $(DOCKER_NAME)

build-44: ## Build version 4.4.x
	@$(MAKE) -f $(THIS) build MDB_VERSION=4.4 DOCKER_FILE=Dockerfile.44

build-50: ## Build version 5.0.x
	@$(MAKE) -f $(THIS) build MDB_VERSION=5.0 DOCKER_FILE=Dockerfile.50

# EOF