## -*- docker-image-name: "emmo-python" -*-
#
# Build this docker with
#
#     docker build -t jesperfriis/emmo-python:$VERSION .
#
# Run this docker (with optional command)
#
#     docker run -i -t jesperfriis/emmo-python:$VERSION [CMD...]
#
# Upload the image to Docker Hub
#
#     docker push jesperfriis/emmo-python:$VERSION
#


## === Dependencies ===
#FROM ubuntu:20.04 AS dependencies
FROM ubuntu:18.04 AS dependencies

# Ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# Configure timezone to avoid that apt-get hangs
ENV TZ=Europe/Oslo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Update apt and install wget and python
RUN set -eux; \
    apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        gnupg \
        software-properties-common \
        wget \
        git \
        python3

# Install and check pandoc
ENV PANDOC_DOWNLOAD_SHA256 4b09f94242d1ad081d9e279f8a873680d06d12bdff2bdc55d50b0bea7864da73
RUN set -eux; \
    wget -O pandoc-amd64.deb \
        https://github.com/jgm/pandoc/releases/download/2.1.2/pandoc-2.1.2-1-amd64.deb
RUN set -eux; \
    echo "$PANDOC_DOWNLOAD_SHA256 pandoc-amd64.deb" | \
         sha256sum -c --strict --check
RUN set -eux; \
        apt-get install -y ./pandoc-amd64.deb

# Install other apt packages that EMMO-python depends on
RUN set -eux; \
    apt-get install -y --no-install-recommends \
        python3-pip \
        graphviz \
        texlive-xetex \
        texlive-latex-extra && \
    rm -rf /var/lib/apt/lists/*

# Create and become a normal user
RUN useradd -ms /bin/bash user
USER user
ENV PATH "/home/user/.local/bin:${PATH}"
WORKDIR "/home/user"

# Upgrade pip and install Python requirements used by the entrypoint
RUN python3 -m pip install --upgrade pip
RUN pip3 install --trusted-host files.pythonhosted.org \
        ipython

# Use pip to install python requirements
COPY requirements.txt .
RUN pip3 install -r requirements.txt


## === Setup ===
FROM dependencies AS setup

# Install EMMO-python
COPY \
        README.md \
        LICENSE.txt \
        setup.py MANIFEST.in \
        /home/user/
RUN mkdir emmo tools
COPY emmo/*.py /home/user/emmo/
COPY --chown=user \
        tools/emmocheck \
        tools/ontodoc \
        tools/ontograph \
        tools/ontoversion \
        tools/ontoconvert \
        /home/user/tools/
RUN chmod +x tools/*
RUN python3 setup.py install --user


# Set up entrypoint
COPY --chown=user docker-entrypoint.sh .
RUN chmod +x docker-entrypoint.sh

ENTRYPOINT ["/home/user/docker-entrypoint.sh"]
CMD ["ipy"]
