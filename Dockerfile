FROM python:bullseye as python


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


#install maven hdf5-tools deps
RUN apt-get update && apt-get install -y maven hdf5-tools libblosc-dev && mkdir -p /opt/bin

ENV PATH $PATH:/opt/bin

#install n5-utils
RUN cd /opt && git clone https://github.com/saalfeldlab/n5-utils && cd n5-utils && ./install /opt/bin

#install bigstitcher-spark, and customize launcher to include args for mem and cpu 
RUN cd /opt && git clone https://github.com/JaneliaSciComp/BigStitcher-Spark.git && cd BigStitcher-Spark && ./install -t 32 -m 128 && \ 
 sed 's/-Xmx128g/-Xmx${1}/' affine-fusion  | sed 's/local\[32\]/local\[${2}\]/' | sed 's/JAR=/if \[ "$#" -lt 2 \]; then echo "Usage : $0 <mem (e.g. 32g)> <cpus (e.g. 16)"; exit 1; fi\nJAR=/g' > /opt/bin/affine-fusion-custom && chmod a+x /opt/bin/affine-fusion-custom


# Install Fiji.
RUN mkdir /opt/fiji \
 && cd /opt/fiji \
 && wget -q https://downloads.imagej.net/fiji/archive/20240208-1017/fiji-nojre.zip \
 && unzip fiji-nojre.zip \
 && rm fiji-nojre.zip

# Add fiji to the PATH
ENV PATH $PATH:/opt/fiji/Fiji.app


# Update URLs use https
RUN ImageJ-linux64 --update edit-update-site ImageJ https://update.imagej.net/ \
 && ImageJ-linux64 --update edit-update-site Fiji https://update.fiji.sc/ \
 && ImageJ-linux64 --update edit-update-site Java-8 https://sites.imagej.net/Java-8/


#install bigstitcher
RUN ImageJ-linux64 --update  add-update-site BigStitcher https://sites.imagej.net/BigStitcher/ \
 && ImageJ-linux64  --update refresh-update-sites \
 && ImageJ-linux64  --update  update \
 && ImageJ-linux64  --update  list 


ENTRYPOINT ["/bin/bash"]
