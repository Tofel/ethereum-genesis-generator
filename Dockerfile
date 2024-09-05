FROM golang:1.23 as builder
RUN git clone https://github.com/protolambda/eth2-testnet-genesis.git  \
    && cd eth2-testnet-genesis \
    && go install . \
    && go install github.com/protolambda/eth2-val-tools@latest \
    && go install github.com/protolambda/zcli@latest

FROM debian:latest
WORKDIR /work
VOLUME ["/config", "/data"]
EXPOSE 8000/tcp

ENV USER=1000
ENV GROUP=1000

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    ca-certificates build-essential python3 python3-dev python3.11-venv python3-venv python3-pip gettext-base jq wget curl && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY apps /apps

ENV PATH="/root/.cargo/bin:${PATH}"
RUN cd /apps/el-gen && python3 -m venv .venv && /apps/el-gen/.venv/bin/pip3 install -r /apps/el-gen/requirements.txt

RUN groupadd -r -g $GROUP $USER && \
    useradd -r -u $USER -g $GROUP --create-home $USER

COPY --from=builder --chown=$USER /go/bin/eth2-testnet-genesis /usr/local/bin/eth2-testnet-genesis
COPY --from=builder --chown=$USER /go/bin/eth2-val-tools /usr/local/bin/eth2-val-tools
COPY --from=builder --chown=$USER /go/bin/zcli /usr/local/bin/zcli
COPY --chown=$USER config-example /config
COPY --chown=$USER defaults /defaults
COPY --chown=$USER entrypoint.sh .

ENTRYPOINT [ "/work/entrypoint.sh" ]