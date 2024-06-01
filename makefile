# This is for local development and testing of the container image and not intended to be used to run the server for play

# Image values
REGISTRY := "localhost"
IMAGE := "soulmask-test"
IMAGE_REF := $(REGISTRY)/$(IMAGE)
GIT_HASH := $(shell git rev-parse --short=8 HEAD)

# Podman Options
CONTAINER_NAME := "soulmask-dev"
VOLUME_NAME := "soulmask-data-dev"
PODMAN_BUILD_OPTS := --build-arg="IMAGE_VERSION=$(GIT_HASH)-devel" --format docker -f ./container/Containerfile
PODMAN_RUN_OPTS := --name $(CONTAINER_NAME) --env=GAME_MODE="pve" --stop-timeout 90 -d --mount type=volume,source=$(VOLUME_NAME),target=/home/steam/soulmask

# Makefile targets
.PHONY: build run run-no-vol clean-all clean-build clean-volume clean-image

build:
	podman build $(PODMAN_BUILD_OPTS) -t $(IMAGE_REF):latest ./container

run:
	podman volume create $(VOLUME_NAME)
	podman run $(PODMAN_RUN_OPTS) $(IMAGE_REF):latest

run-no-vol:
	podman run $(PODMAN_RUN_OPTS) $(IMAGE_REF):latest

# Clean all artifacts
clean-all:
	podman rm -f $(CONTAINER_NAME)
	podman rmi -f $(IMAGE_REF):latest
	podman volume rm $(VOLUME_NAME)

# Clean container and volume
clean-build:
	podman rm -f $(CONTAINER_NAME)
	podman volume rm $(VOLUME_NAME)

# Clean container
clean-container:
	podman rm -f $(CONTAINER_NAME)

# Clean volume
clean-volume:
	podman volume rm $(VOLUME_NAME)

# Clean image
clean-image:
	podman rmi -f $(IMAGE_REF):latest
