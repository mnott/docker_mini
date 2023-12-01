FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install --no-install-recommends -y \
    ssh \
    iputils-ping \
    net-tools \
    vim

COPY src/ /

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /root
#CMD ["sh", "-c", "service ssh start && while :; do sleep 1; done"]

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["service ssh start && while :; do sleep 1; done"]

