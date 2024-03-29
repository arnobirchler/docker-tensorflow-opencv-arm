#TODO change image
FROM armhf/debian

# Install dependancies
RUN apt-get update && apt-get -q -y install --no-install-recommends curl unzip openssl ca-certificates \

# build tools for python and cmake
build-essential tk-dev libncurses5-dev libncursesw5-dev libreadline6-dev \
libdb5.3-dev libgdbm-dev libsqlite3-dev libssl-dev \
libbz2-dev libexpat1-dev liblzma-dev zlib1g-dev pkg-config \

# Tensorflow
libjpeg-dev libtiff5-dev libjasper-dev \
libpng12-dev libavcodec-dev libavformat-dev libswscale-dev \
libv4l-dev libxvidcore-dev libx264-dev libhdf5-dev \
python3-yaml python3-scipy python3-h5py \

# OpenCv
libgtk-3-dev libcanberra-gtk* libatlas-base-dev gfortran && \

# Clean
apt-get clean && rm -rf /var/lib/apt/lists/*

#Install Python3.5
RUN curl -L -k https://www.python.org/ftp/python/3.5.2/Python-3.5.2.tgz > Python-3.5.2.tgz && tar -zxvf Python-3.5.2.tgz && rm Python-3.5.2.tgz && \
    (cd Python-3.5.2 && ./configure --enable-shared --prefix=/usr/local/opt/python-3.5.2 && make && make install) && rm /Python-3.5.2/ -rf

RUN ln -s /usr/local/opt/python-3.5.2/bin/pydoc3.5 /usr/bin/pydoc3.5 && \
    ln -s /usr/local/opt/python-3.5.2/bin/python3.5 /usr/bin/python3.5 && \
    ln -s /usr/local/opt/python-3.5.2/bin/python3.5m /usr/bin/python3.5m && \
    ln -s /usr/local/opt/python-3.5.2/bin/pyvenv-3.5 /usr/bin/pyvenv-3.5 && \
    ln -s /usr/local/opt/python-3.5.2/bin/pip3.5 /usr/bin/pip3.5

ENV LD_LIBRARY_PATH="/usr/local/opt/python-3.5.2/lib"

#upgrade PIP
RUN pip3.5 install --upgrade pip

#Cmake
RUN curl -L -k https://cmake.org/files/v3.5/cmake-3.5.1.tar.gz > cmake-3.5.1.tar.gz && tar -xf cmake-3.5.1.tar.gz && rm cmake-3.5.1.tar.gz && \
(cd cmake-3.5.1 && ./bootstrap && make && make install) && rm /cmake-3.5.1 -rf

# Keras Tensorflow
ENV CXXFLAGS="-std=c++11"
ENV CFLAGS="-std=c99"
RUN pip3.5 install numpy pyzmq kiwisolver pillow && echo "[global]" >> /etc/pip.conf && echo "extra-index-url=https://www.piwheels.org/simple" >> /etc/pip.conf && pip3.5 install certifi tensorflow SimpleWebSocketServer

# OpenCV
RUN curl -L -k https://github.com/opencv/opencv/archive/4.0.0.zip > opencv.zip && curl -L -k https://github.com/opencv/opencv_contrib/archive/4.0.0.zip > opencv_contrib.zip && \
    unzip opencv.zip && unzip opencv_contrib.zip && mv opencv-4.0.0 /opt/opencv && mv opencv_contrib-4.0.0 /opt/opencv_contrib && mkdir /opt/opencv/build && \

    # Install
    ( cd /opt/opencv/build && cmake -D CMAKE_BUILD_TYPE=RELEASE \
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
    -D BUILD_EXAMPLES=OFF .. && \
    make -j4 && make install && ldconfig && \
    python3.5 /usr/local/python/setup.py config && python3.5 /usr/local/python/setup.py develop) && \

    # Clean
    rm opencv.zip && rm opencv_contrib.zip && rm /opt/* -rf

   
# for protocbuf : autoconf automake libtool && \
#Install C++ Protocol Compiler
RUN curl -L https://github.com/protocolbuffers/protobuf/releases/download/v3.9.1/protobuf-all-3.9.1.zip > protobuf.zip && mkdir /opt/protobuf && unzip protobuf.zip -d /opt/ && \
    (cd /opt/protobuf-3.9.1 && ./configure && make && make check && make install && \
     #Build python runtime library   
    export LD_LIBRARY_PATH="$(LD_LIBRARY_PATH):../src/.libs" && \
    python3.5 setup.py build --cpp_implementation && python3.5 setup.py install --cpp_implementation && export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp && PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2 && ldconfig) && \
    rm /opt/protobuf-3.9.1 -rf && rm protobuf.zip


# models
RUN mkdir /home/models
COPY models /home/models
#Add env path
ENV PYTHONPATH="${PYTHONPATH}:/home/models"
ENV PYTHONPATH="${PYTHONPATH}:/home/models/research"
ENV PYTHONPATH="${PYTHONPATH}:/home/models/research/slim"

#RUN (cd /home/models/research && protoc --python_out=. object_detection/protos/*)

#RUN rm protobuf.zip
EXPOSE 8000
EXPOSE 8765
EXPOSE 5555
