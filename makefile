.PHONY: run build clean

#Use command: make (your option: run, build, clean)
PLUGDEV_GID := $(shell getent group plugdev | cut -d: -f3)

run:
	docker run -it --rm \
		--name flutter-dev \
		--privileged \
		--device /dev/kvm \
		-v /tmp/.x11-unix:/tmp/.x11-unix \
		-e DISPLAY=$(DISPLAY) \
		-v /dev/bus/usb:/dev/bus/usb \
		--group-add $(PLUGDEV_GID) \
		-v $$(pwd):/workspace \
		-v $$HOME/.gradle:/root/.gradle \
		-v $$HOME/.pub-cache:/root/.pub-cache \
		flutter-full-power

build:
	docker build -t flutter-full-power .

clean:
	docker rmi flutter-full-power
