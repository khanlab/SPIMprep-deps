FROM python:3.11-bullseye as python

#install gcloud cli
RUN apt-get update \ 
    && apt-get install -y wget \
    && cd /opt && wget https://storage.googleapis.com/cloud-sdk-release/google-cloud-cli-484.0.0-linux-x86_64.tar.gz \
    && tar -xvzf google-cloud-cli-484.0.0-linux-x86_64.tar.gz 

ENV PATH $PATH:/opt/google-cloud-sdk/bin

#install java from Amazon corretto
ARG version=8.402.08-1
# In addition to installing the Amazon corretto, we also install
# fontconfig. The folks who manage the docker hub's
# official image library have found that font management
# is a common usecase, and painpoint, and have
# recommended that Java images include font support.
#
# See:
#  https://github.com/docker-library/official-images/blob/master/test/tests/java-uimanager-font/container.java

RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        curl ca-certificates gnupg software-properties-common fontconfig java-common \
    && curl -fL https://apt.corretto.aws/corretto.key | apt-key add - \
    && add-apt-repository 'deb https://apt.corretto.aws stable main' \
    && mkdir -p /usr/share/man/man1 || true \
    && apt-get update \
    && apt-get install -y java-1.8.0-amazon-corretto-jdk=1:$version \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
        curl gnupg software-properties-common

ENV LANG C.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-amazon-corretto


#install maven hdf5-tools deps, 7zip (for zarr zipstore archiving), libvips
RUN apt-get update && apt-get install -y maven hdf5-tools libblosc-dev p7zip-full libxtst-dev libvips-dev && mkdir -p /opt/bin

ENV PATH $PATH:/opt/bin

#install n5-utils
RUN cd /opt && git clone https://github.com/saalfeldlab/n5-utils && cd n5-utils && ./install /opt/bin

#install bigstitcher-spark, and customize launcher to include args for mem and cpu 
RUN cd /opt && git clone https://github.com/akhanf/BigStitcher-Spark.git
COPY spark_custom_install /opt/BigStitcher-Spark/install
RUN cd /opt/BigStitcher-Spark && ./install -t 32 -m 128

ENV PATH $PATH:/opt/BigStitcher-Spark


# Stage: itksnap (built with Ubuntu16.04 - glibc 2.23)
FROM khanlab/itksnap:main as itksnap
RUN cp -R /opt/itksnap/ /opt/itksnap-mini/ \
    && cd /opt/itksnap-mini/bin \
    && rm c2d itksnap* 

FROM python as runtime
COPY --from=itksnap /opt/itksnap-mini/* /opt/bin


#install pythondeps
COPY . /opt/pythondeps
RUN pip install --no-cache-dir /opt/pythondeps 


ENTRYPOINT ["/bin/bash", "-l", "-c"]

