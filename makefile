# This is for local development and testing of the container image and not intended to be used to run the server for play

# Image values
REGISTRY := "localhost"
IMAGE := "soulmask-test"
IMAGE_REF := $(REGISTRY)/$(IMAGE)

# Podman Options
CONTAINER_NAME := "soulmask-dev"
VOLUME_NAME := "soulmask-data-dev"
PODMAN_BUILD_OPTS := --format docker -f ./container/Containerfile
PODMAN_RUN_OPTS := --name $(CONTAINER_NAME) -d --mount type=volume,source=$(VOLUME_NAME),target=/home/steam/soulmask

# Makefile targets
.PHONY: build run cleanup

build:
	podman build $(PODMAN_BUILD_OPTS) -t $(IMAGE_REF):latest ./container

run:
	podman volume create $(VOLUME_NAME)
	podman run $(PODMAN_RUN_OPTS) $(IMAGE_REF):latest

cleanup:
	podman rm -f $(CONTAINER_NAME)
	podman rmi -f $(IMAGE_REF):latest
	podman volume rm $(VOLUME_NAME)
