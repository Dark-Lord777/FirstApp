From ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install -y \
        curl \
        wget \
        git \
        unzip \
        zip \
        xz-utils \
        openjdk-17-jdk \
        clang \
        cmake \
        ninja-build \
        libgtk-3-dev \
        liblzma-dev \
        x11-apps \
        locales \
        net-tools \
        iputils-ping \
        dnsutils \
        usbutils \
        pciutils \
        lsof \
        nano \
        vim \
        && locale-gen en_US.UTF-8 \
        && rm -rf /var/lib/apt/lists/*

# Android SDK
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    && unzip -q commandlinetools-linux-*_latest.zip -d $ANDROID_SDK_ROOT/cmdline-tools \
    && mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest \
    && rm commandlinetools-linux-*_latest.zip

# Принимаем лицензии
RUN yes | $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager --licenses > /dev/null 2>&1

# Устанавливаем нужные компоненты
RUN $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager \
    "platform-tools" \
    "platforms;android-35" \
    "build-tools;35.0.0" \
    > /dev/null 2>&1

# Flutter SDK (stable channel, НЕ master)
ENV FLUTTER_ROOT=/opt/flutter
ENV PATH=$PATH:$FLUTTER_ROOT/bin
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_ROOT \
    && $FLUTTER_ROOT/bin/flutter config --enable-web \
    && $FLUTTER_ROOT/bin/flutter config --enable-linux-desktop \
    && $FLUTTER_ROOT/bin/flutter precache

ENV GRADLE_USER_HOME=/opt/gradle
RUN mkdir -p $GRADLE_USER_HOME

WORKDIR /workspace

CMD ["/bin/bash"]
