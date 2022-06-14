FROM ubuntu:22.04

RUN apt update && \
    apt install -y git gh rsync

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
