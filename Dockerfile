FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu14.04

MAINTAINER Craig Citro <craigcitro@google.com>

# Pick up some TF dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        git \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \
        pkg-config \
        python \
        python-dev \
        rsync \
        software-properties-common \
        unzip \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

RUN pip --no-cache-dir install \
        ipykernel \
        jupyter \
        matplotlib \
        numpy \
        scipy \
        sklearn \
        pandas \
        Pillow \
        && \
    python -m ipykernel.kernelspec

# Install Bazel
RUN echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list
RUN curl https://bazel.build/bazel-release.pub.gpg | apt-key add -
RUN add-apt-repository ppa:openjdk-r/ppa
RUN apt-get update && apt-get -y install bazel
RUN apt-get -y upgrade bazel
RUN apt-get clean && \
	rm -rf /var/lib/apt/lists/*

RUN cd /root && git clone -b bugfix/kenlm-new-version --verbose https://github.com/timediv/tensorflow-with-kenlm.git tensorflow
SHELL ["/bin/bash", "-c"]
RUN chmod +x /root/tensorflow/configure

RUN cd /root/tensorflow && \
	tensorflow/tools/ci_build/builds/configured GPU \
	bazel build -c opt --config=cuda --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" \
		tensorflow/tools/pip_package:build_pip_package && \
	bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
RUN pip --no-cache-dir install /tmp/tensorflow_pkg/tensorflow-*.whl && \
	rm -rf /tmp/pip && \
    rm -rf /root/.cache
# Clean up pip wheel and Bazel cache when done.

# RUN ln -s /usr/bin/python3 /usr/bin/python#

# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH

# TensorBoard
EXPOSE 6006

# Install Keras dependencies
RUN apt-get update && apt-get install -y \
  libhdf5-dev \
  python-h5py \
  python-yaml

# Install PyTables dependencies
RUN pip --no-cache-dir install \ 
		numpy>=1.8.0 \
		numexpr>=2.5.2 \
		six>=1.9.0

# Install PyTables
RUN pip --no-cache-dir install tables

# Clone Keras repo and move into it
RUN cd /root && git clone https://github.com/fchollet/keras.git && cd keras && \
  # Install
  python setup.py install

# Set ~/keras as working directory
WORKDIR /root/keras
