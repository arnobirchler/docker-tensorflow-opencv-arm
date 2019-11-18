FROM armhf/debian

RUN apt-get update

#Install common tools
RUN apt-get -q -y install --no-install-recommends git curl unzip openssl ca-certificates

#Install Python3.5
RUN apt-get -q -y install --no-install-recommends build-essential \
tk-dev libncurses5-dev libncursesw5-dev libreadline6-dev \
libdb5.3-dev libgdbm-dev libsqlite3-dev libssl-dev \
libbz2-dev libexpat1-dev liblzma-dev zlib1g-dev 
#TODO change path to /opt
RUN curl -L -k https://www.python.org/ftp/python/3.5.2/Python-3.5.2.tgz > Python-3.5.2.tgz
RUN tar -zxvf Python-3.5.2.tgz
RUN (cd Python-3.5.2 && ./configure --enable-shared --prefix=/usr/local/opt/python-3.5.2 && make && make install) 

RUN ln -s /usr/local/opt/python-3.5.2/bin/pydoc3.5 /usr/bin/pydoc3.5
RUN ln -s /usr/local/opt/python-3.5.2/bin/python3.5 /usr/bin/python3.5
RUN ln -s /usr/local/opt/python-3.5.2/bin/python3.5m /usr/bin/python3.5m
RUN ln -s /usr/local/opt/python-3.5.2/bin/pyvenv-3.5 /usr/bin/pyvenv-3.5
RUN ln -s /usr/local/opt/python-3.5.2/bin/pip3.5 /usr/bin/pip3.5

RUN ln -s /usr/bin/python3.5 /usr/bin/python3
RUN ln -s /usr/bin/python3.5 /usr/bin/python
RUN ln -s /usr/bin/pip3.5 /usr/bin/pip3
RUN ln -s /usr/bin/pip3.5 /usr/bin/pip

ENV LD_LIBRARY_PATH="/usr/local/opt/python-3.5.2/lib"

#upgrade PIP
RUN pip install --upgrade pip

RUN apt-get update && \
    apt-get -q -y install --no-install-recommends \
       build-essential cmake \
      pkg-config libjpeg-dev libtiff5-dev libjasper-dev \
      libpng12-dev libavcodec-dev libavformat-dev libswscale-dev \
      libv4l-dev libxvidcore-dev libx264-dev libhdf5-dev \
      python3-yaml python3-scipy python3-h5py

#Cmake
RUN curl -L -k https://cmake.org/files/v3.5/cmake-3.5.1.tar.gz > cmake-3.5.1.tar.gz
RUN tar -xf cmake-3.5.1.tar.gz
RUN (cd cmake-3.5.1 && ./bootstrap)
RUN (cd cmake-3.5.1 && make && make install)

# Keras Tensorflow
#RUN pip3 install keras
ADD https://github.com/lhelontra/tensorflow-on-arm/releases/download/v1.14.0-buster/tensorflow-1.14.0-cp35-none-linux_armv7l.whl /tensorflow-1.14.0-cp35-none-linux_armv7l.whl
ENV CXXFLAGS="-std=c++11"
ENV CFLAGS="-std=c99"
RUN pip3 install certifi
RUN pip3 install /tensorflow-1.14.0-cp35-none-linux_armv7l.whl && rm /tensorflow-1.14.0-cp35-none-linux_armv7l.whl

# OpenCV
RUN apt-get -q -y install --no-install-recommends libgtk-3-dev libcanberra-gtk* libatlas-base-dev gfortran
RUN curl -L -k https://github.com/opencv/opencv/archive/4.0.0.zip > opencv.zip
RUN curl -L -k https://github.com/opencv/opencv_contrib/archive/4.0.0.zip > opencv_contrib.zip
RUN unzip opencv.zip && unzip opencv_contrib.zip 
RUN mv opencv-4.0.0 /opt/opencv && mv opencv_contrib-4.0.0 /opt/opencv_contrib
RUN mkdir /opt/opencv/build
RUN ( cd /opt/opencv/build && cmake -D CMAKE_BUILD_TYPE=RELEASE \
-D CMAKE_INSTALL_PREFIX=/usr/local \
-D OPENCV_EXTRA_MODULES_PATH=/opt/opencv_contrib/modules \
-D ENABLE_NEON=ON \
-D ENABLE_VFPV3=ON \
-D BUILD_TESTS=OFF \
-D OPENCV_ENABLE_NONFREE=ON \
-D INSTALL_PYTHON_EXAMPLES=OFF \
-D BUILD_opencv_xfeatures2d=OFF \
-D BUILD_opencv_python3=yes \
-D PYTHON3_EXECUTABLE=/usr/bin/python3.5 \
-D PYTHON3_INCLUDE_DIR=/usr/local/opt/python-3.5.2/include/python3.5m \
-D PYTHON3_INCLUDE_DIR2=/usr/local/opt/python-3.5.2/include/python3.5m \
-D PYTHON3_LIBRARY=/usr/local/opt/python-3.5.2/lib/libpython3.so \
-D PYTHON3_NUMPY_INCLUDE_DIR=/usr/local/opt/python-3.5.2/lib/python3.5/site-packages/numpy/core/include \
-D PYTHON3_PACKAGES_PATH=/usr/local/opt/python-3.5.2/lib/python3.5/site-packages \
-D BUILD_EXAMPLES=OFF ..)
RUN ( cd /opt/opencv/build && make -j4 && \
        make install && \
        ldconfig )
   
# for protocbuf : autoconf automake libtool && \
#Install C++ Protocol Compiler
#RUN curl -L https://github.com/protocolbuffers/protobuf/releases/download/v3.9.1/protobuf-all-3.9.1.zip > protobuf.zip
#RUN mkdir /opt/protobuf
#RUN unzip protobuf.zip -d /opt/protobuf
#RUN (cd /opt/protobuf-3.9.1 && ./configure)
#RUN (cd /opt/protobuf-3.9.1 && make)
#RUN (cd /opt/protobuf-3.9.1 && make check)
#RUN (cd /opt/protobuf-3.9.1 && make install)

#Build python runtime library
#RUN (cd /opt/protobuf-3.9.1/python && export LD_LIBRARY_PATH=../src/.libs)
#RUN (cd /opt/protobuf-3.9.1/python && python setup.py build --cpp_implementation)
#RUN (cd /opt/protobuf-3.9.1/python && python setup.py test --cpp_implementation)
#RUN (cd /opt/protobuf-3.9.1/python && python setup.py install --cpp_implementation)
#ENV PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
#ENV PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2
#RUN (cd /opt/protobuf-3.9.1/python && ldconfig)

# models
RUN mkdir /home/models
COPY models /home/models
#Add env path
ENV PYTHONPATH="${PYTHONPATH}:/home/models"
ENV PYTHONPATH="${PYTHONPATH}:/home/models/research"
ENV PYTHONPATH="${PYTHONPATH}:/home/models/research/slim"

#RUN (cd /home/models/research && protoc --python_out=. object_detection/protos/*)

#clean install
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN rm opencv.zip && rm opencv_contrib.zip
RUN rm /tensorflow-1.14.0-cp35-none-linux_armv7l.whl
RUN rm Python-3.5.2.tgz
RUN rm protobuf.zip

EXPOSE 8888
EXPOSE 6006
