FROM python:3.11.17-bookworm

ARG DEBIAN_FRONTEND=noninteractive

ENV LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8

RUN apt-get -y update \
    && apt-get -y install curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT [ "/usr/bin/curl" ]
CMD [ "--silent", "https://icanhazip.com" ]
