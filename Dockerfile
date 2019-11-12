# Dockerfile with tensorflow gpu support on python3, opencv3.3
FROM elswork/tensorflow-diy:armv7l
FROM sixsq/opencv-python
RUN mkdir /home/models
# RUN pip install Pillow opencv-python contextlib2 Cython
RUN apt-get update
RUN apt-get install -y git libsm6 libxext6 libxrender-dev curl unzip x264

COPY models /home/models

RUN curl -L https://github.com/protocolbuffers/protobuf/releases/download/v3.9.1/protoc-3.9.1-linux-x86_64.zip > protoc.zip
RUN mkdir /opt/protoc
RUN unzip protoc.zip -d /opt/protoc
RUN rm protoc.zip
ENV PATH="/opt/protoc/bin:${PATH}"
ENV PYTHONPATH="${PYTHONPATH}:/home/models"
ENV PYTHONPATH="${PYTHONPATH}:/home/models/research"
ENV PYTHONPATH="${PYTHONPATH}:/home/models/research/slim"
RUN (cd /home/models/research && protoc --python_out=. object_detection/protos/*)

EXPOSE 8888
EXPOSE 6006
