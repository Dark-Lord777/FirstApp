.PHONY: run build clean shell

# Use command: make (your option: run, build, clean, shell)
PLUGDEV_GID := $(shell getent group plugdev | cut -d: -f3)

run:
	docker run -it --rm \
		--name flutter-dev \
		--hostname flutter-dev-machine \
		--privileged \
		--device /dev/kvm \
		-v /tmp/.x11-unix:/tmp/.x11-unix \
		-e DISPLAY=$$(DISPLAY) \
		-v /dev/bus/usb:/dev/bus/usb \
		--group-add $(PLUGDEV_GID) \
		--network host \
		-v $$(pwd):/workspace \
		-v $$HOME/.gradle:/opt/gradle \
		-v $$HOME/.pub-cache:/root/.pub-cache \
		-v $$HOME/.android:/root/.android \
		-v $$HOME/.cache/apt:/var/cache/apt \
		-v $$HOME/.cache/apt_lists:/var/lib/apt/lists \
		flutter-full-power

shell:
	docker exec -it flutter-dev bash

build:
	docker build -t flutter-full-power .

clean:
	docker rmi flutter-full-power
