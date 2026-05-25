From ubuntu:22.04

RUN apt-get update && apt-get install -y \ 
        curl \
        zsh \
        git \
        unzip \
        zip\
        xz-utils \
        openjdk-17-jdk \
        wget \
        #For compiling Linux desktop 
        clang \
        cmake \
        ninja-build \
        libgtk-3-dev \
        liblzma-dev \
        #hot reload and debugging
        #android-sdk-platforms-tools-common \
        x11-apps \
        #when you download a list avaliable packages you download expect 
        #for the necessary packages still garbage. and command down delete this garbage 
        && rm -rf /var/lib/apt/lists/*

#Install Android SDK
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:ANDROID_SDK_ROOT/platforms-tools
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools \
        && wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
        && unzip commandlinetools-linux-*_latest.zip -d $ANDROID_SDK_ROOT/cmdline-tools \
        && mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest \
        && rm commandlinetools-linux-*_latest.zip 
        #Accept license 
        RUN yes | sdkmanager --licenses > /dev/null 2>&1 || true
        RUN sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

#Install flutter sdk
ENV FLUTTER_ROOT=/opt/flutter
ENV PATH=$PATH:$FLUTTER_ROOT/bin
RUN git clone  https://github.com/flutter/flutter.git $FLUTTER_ROOT
#Enable support web and linux
RUN flutter config --enable-web && flutter config --enable-linux-desktop
#cached insruments
RUN flutter precache
#Install shell. Not necessary
ENV SHELL=/bin/zsh

RUN echo 'BLUE=$(printf "\033[95m")' >> /root/.zshrc \
    && echo 'GREEN=$(printf "\033[32m")' >> /root/.zshrc \
    && echo 'RESET=$(printf "\033[0m")' >> /root/.zshrc \
    && echo 'TOP_LEFT="┌"' >> /root/.zshrc \
    && echo 'VERTICAL="│"' >> /root/.zshrc \
    && echo 'BOTTOM_LEFT="└"' >> /root/.zshrc \
    && echo 'HORIZONTAL="─"' >> /root/.zshrc \
    && echo 'WELCOME="Welcome Lord of Docker"' >> /root/.zshrc \
    && echo 'build_prompt() {' >> /root/.zshrc \
    && echo '  local dir="%~"' >> /root/.zshrc \
    && echo '  PROMPT="${BLUE}${TOP_LEFT}${HORIZONTAL}${HORIZONTAL} ${WELCOME} ${GREEN}${dir}${RESET}\n${BLUE}${VERTICAL}${RESET}\n${BLUE}${BOTTOM_LEFT}${HORIZONTAL}${RESET} -> "' >> /root/.zshrc \
    && echo '}' >> /root/.zshrc \
    && echo 'precmd() { build_prompt }' >> /root/.zshrc

RUN git clone https://github.com/zsh-users/zsh-autosuggestions /root/.zsh/zsh-autosuggestions \
    && echo "source /root/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" >> /root/.zshrc
WORKDIR /workspace
CMD ["zsh"]

