FROM armhf/debian

RUN apt-get update && \
    apt-get -q -y install --no-install-recommends python3 \
      python3-dev python3-pip build-essential cmake \
      pkg-config libjpeg-dev libtiff5-dev libjasper-dev \
      libpng12-dev libavcodec-dev libavformat-dev libswscale-dev \
      libv4l-dev libxvidcore-dev libx264-dev python3-yaml \
      python3-scipy python3-h5py git curl unzip autoconf automake libtool && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
    
# Keras Tensorflow
RUN pip3 install keras
ADD https://github.com/samjabrahams/tensorflow-on-raspberry-pi/releases/download/v1.0.0/tensorflow-1.0.0-cp34-cp34m-linux_armv7l.whl /tensorflow-1.0.0-cp34-cp34m-linux_armv7l.whl
RUN pip3 install /tensorflow-1.0.0-cp34-cp34m-linux_armv7l.whl && rm /tensorflow-1.0.0-cp34-cp34m-linux_armv7l.whl

# OpenCV
ENV OPENCV_VERSION="3.2.0"
ENV OPENCV_DIR="/opt/opencv/"

ADD https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.tar.gz ${OPENCV_DIR}

RUN cd ${OPENCV_DIR} && \
    tar -xzf ${OPENCV_VERSION}.tar.gz && \
    rm ${OPENCV_VERSION}.tar.gz && \
    mkdir ${OPENCV_DIR}opencv-${OPENCV_VERSION}/build && \
    cd ${OPENCV_DIR}opencv-${OPENCV_VERSION}/build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local .. && make -j4 && make install && \
    mv /usr/local/lib/python3.4/dist-packages/cv2.cpython-34m.so /usr/local/lib/python3.4/dist-packages/cv2.so && \
    rm -rf ${OPENCV_DIR}
   
# models
RUN mkdir /home/models
COPY models /home/models

#Install C++ Protocol Compiler
RUN curl -L https://github.com/protocolbuffers/protobuf/releases/download/v3.9.1/protobuf-all-3.9.1.zip > protobuf.zip
RUN mkdir /opt/protobuf
RUN unzip protobuf.zip -d /opt/protobuf
RUN rm protobuf.zip
RUN (cd /opt/protobuf-3.9.1 && ./configure)
RUN (cd /opt/protobuf-3.9.1 && make)
RUN (cd /opt/protobuf-3.9.1 && make check)
RUN (cd /opt/protobuf-3.9.1 && make install)

#Build python runtime library
RUN (cd /opt/protobuf-3.9.1/python && export LD_LIBRARY_PATH=../src/.libs)
RUN (cd /opt/protobuf-3.9.1/python && python setup.py build --cpp_implementation)
RUN (cd /opt/protobuf-3.9.1/python && python setup.py test --cpp_implementation)
RUN (cd /opt/protobuf-3.9.1/python && python setup.py install --cpp_implementation)
ENV PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
ENV PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2
RUN (cd /opt/protobuf-3.9.1/python && ldconfig)

#Add env path
ENV PYTHONPATH="${PYTHONPATH}:/home/models"
ENV PYTHONPATH="${PYTHONPATH}:/home/models/research"
ENV PYTHONPATH="${PYTHONPATH}:/home/models/research/slim"

RUN (cd /home/models/research && protoc --python_out=. object_detection/protos/*)

EXPOSE 8888
EXPOSE 6006
