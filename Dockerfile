FROM quay.io/coreos/etcd:v3.3.12
LABEL maintainer="Chris Cosby <chris.cosby@aptplatforms.com>"

RUN apk update \
 && apk upgrade --purge \
 && apk add tini bash \
 && rm -f /var/cache/apk/*

ARG DATA_DIR=/data

ENV CLIENT_PORT=2379 \
    PEER_PORT=2380 \
    LISTEN_IP_ADDRESS=0.0.0.0 \
    ETCD_NAME= \
    ETCD_INITIAL_CLUSTER_TOKEN=etcd-cluster-token \
    ETCD_DATA_DIR=$DATA_DIR

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s CMD ["/usr/local/bin/etcdctl", "cluster-health"]

COPY boot.sh /boot.sh

EXPOSE $CLIENT_PORT $PEER_PORT
VOLUME $ETCD_DATA_DIR

ENTRYPOINT ["/sbin/tini", "-v", "--"]
CMD ["/bin/bash", "/boot.sh"]
