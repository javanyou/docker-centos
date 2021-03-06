FROM centos:7

RUN yum install -y epel-release
# install FFmpeg according to the official documentation on how to install
# FFmpeg on CentOS: https://trac.ffmpeg.org/wiki/CompilationGuide/Centos

# Get the Dependencies
RUN yum install -y autoconf automake bzip2 bzip2-devel freetype-devel gcc gcc-c++ git libtool make mercurial pkgconfig zlib-devel

RUN mkdir /tmp/ffmpeg_sources

# cmake 
RUN cd /tmp/ffmpeg_sources && \
    curl -O -L https://cmake.org/files/v3.6/cmake-3.6.0.tar.gz && \
    tar -zxvf cmake-3.6.0.tar.gz && \
    cd cmake-3.6.0 && \
    ./bootstrap && \
    gmake && \
    gmake install
    
# NASM
RUN cd /tmp/ffmpeg_sources && \
    curl -O -L http://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.bz2 && \
    tar xjvf nasm-2.14.02.tar.bz2 && \
    cd nasm-2.14.02 && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install

# Yasm
RUN cd /tmp/ffmpeg_sources && \
    curl -O -L http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz && \
    tar xzvf yasm-1.3.0.tar.gz && \
    cd yasm-1.3.0 && \
    ./configure && \
    make && \
    make install

# libx264
RUN cd /tmp/ffmpeg_sources && \
    git clone --depth 1 https://code.videolan.org/videolan/x264.git && \
    cd x264 && \
    PATH="$PATH:/tmp/bin" PKG_CONFIG_PATH="/tmp/ffmpeg_build/lib/pkgconfig" ./configure --prefix="/tmp/ffmpeg_build" --bindir="/tmp/bin" --enable-static && \
    PATH="$PATH:/tmp/bin" make && \
    make install

# libx265
RUN cd /tmp/ffmpeg_sources && \
    hg clone https://bitbucket.org/multicoreware/x265 && \
    cd /tmp/ffmpeg_sources/x265/build/linux && \
    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="/tmp/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source && \
    make && \
    make install

# libfdk_aac
RUN cd /tmp/ffmpeg_sources && \
    git clone --depth 1 https://github.com/mstorsjo/fdk-aac && \
    cd fdk-aac && \
    autoreconf -fiv && \
    ./configure --prefix="/tmp/ffmpeg_build" --disable-shared && \
    make && \
    make install

# libmp3lame
RUN cd /tmp/ffmpeg_sources && \
    curl -O -L http://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz && \
    tar xzvf lame-3.100.tar.gz && \
    cd lame-3.100 && \
    ./configure --prefix="/tmp/ffmpeg_build" --bindir="/tmp/bin" --disable-shared --enable-nasm && \
    make && \
    make install

# libopus
RUN cd /tmp/ffmpeg_sources && \
    curl -O -L https://archive.mozilla.org/pub/opus/opus-1.3.tar.gz && \
    tar xzvf opus-1.3.tar.gz && \
    cd opus-1.3 && \
    PKG_CONFIG_PATH="/tmp/ffmpeg_build/lib/pkgconfig" ./configure --prefix="/tmp/ffmpeg_build" --disable-shared && \
    make && \
    make install

# libvpx
RUN cd /tmp/ffmpeg_sources && \
    git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git && \
    cd libvpx && \
    ./configure --prefix="/tmp/ffmpeg_build" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm && \
    PATH="$PATH:/tmp/bin" make && \
    make install

# Install git lfs support.
RUN curl -s curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.rpm.sh  | bash
RUN yum install -y git-lfs
RUN git lfs install --skip-repo

# Add the user UID:1000, GID:1000, home at /master
RUN groupadd -r master -g 1000 && useradd -u 1000 -r -g master -m -d /home/master -s /sbin/nologin -c "master user" master && \
    chmod 755 /home/master

# Set the working directory to app home directory
WORKDIR /home/master

# Specify the user to execute all commands below
USER master
