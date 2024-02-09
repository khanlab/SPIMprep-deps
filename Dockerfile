# Stage: python deps
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

#install maven hdf5-tools
RUN apt-get update && apt-get install -y maven hdf5-tools && mkdir -p /opt/bin

ENV PATH $PATH:/opt/bin

#install n5-utils
RUN cd /opt && git clone https://github.com/saalfeldlab/n5-utils && cd n5-utils && ./install /opt/bin

#install bigstitcher-spark
RUN cd /opt && git clone https://github.com/JaneliaSciComp/BigStitcher-Spark.git && cd BigStitcher-Spark && ./install -t 32 -m 128 && cp affine-fusion /opt/bin




# Create a user.
#RUN useradd -u 1000 -ms /bin/bash fiji
#RUN mkdir /opt/fiji && chown fiji:fiji /opt/fiji
#USER fiji

# Define working directory.
WORKDIR /opt/fiji


# Install Fiji.
RUN wget -q https://downloads.imagej.net/fiji/archive/20240208-1017/fiji-nojre.zip \
 && unzip fiji-nojre.zip \
 && rm fiji-nojre.zip

# Add fiji to the PATH
ENV PATH $PATH:/opt/fiji/Fiji.app

# Define entrypoint.
COPY --chown=fiji:fiji entrypoint.sh /opt/fiji
ENTRYPOINT ["./entrypoint.sh"]

# Update URLs use https
RUN ./entrypoint.sh --update edit-update-site ImageJ https://update.imagej.net/
RUN ./entrypoint.sh --update edit-update-site Fiji https://update.fiji.sc/
RUN ./entrypoint.sh --update edit-update-site Java-8 https://sites.imagej.net/Java-8/

# Run once to create Java preferences.
COPY --chown=fiji:fiji demo.py /opt/fiji/
RUN ./entrypoint.sh --headless --ij2 --console --run ./demo.py 'name="test"'

#install bigstitcher
RUN ImageJ-linux64 --update  add-update-site BigStitcher https://sites.imagej.net/BigStitcher/ && ImageJ-linux64  --update refresh-update-sites && ImageJ-linux64  --update  update && ImageJ-linux64  --update  list 


