#!/bin/bash

# We use the official etcd environment variable names to keep flag usage to a minimum
# https://coreos.com/etcd/docs/latest/op-guide/configuration.html

# Set CLUSTER_LEAD for nodes other than the initial node. This is the trigger
# to add this host to the cluster.

# Set ETCD_NAME to a unique hostname. `hostname` is a good idea, but isn't
# optimal for Docker environments, especially when you upgrade containers.
export ETCD_NAME=${ETCD_NAME:-$(hostname)}

# ETCD_CLUSTER_TOKEN should be something unique.
export ETCD_INITIAL_CLUSTER_TOKEN=${ETCD_INITIAL_CLUSTER_TOKEN:-etcd-cluster-token}

export CLIENT_PORT=${CLIENT_PORT:-2379}
export PEER_PORT=${PEER_PORT:-2380}
export LISTEN_IP_ADDRESS=${LISTEN_IP_ADDRESS:-0.0.0.0}
export ETCD_DATA_DIR=${ETCD_DATA_DIR:-/data}

IP_ADDRESS=`ip route get 1 | awk '{print $NF; exit}'`

if [[ -z "$CLUSTER_LEAD" ]]; then
    export ETCD_INITIAL_CLUSTER_STATE=new
    export ETCD_INITIAL_CLUSTER="$ETCD_NAME=http://$IP_ADDRESS:$PEER_PORT"

else
    export ETCD_INITIAL_CLUSTER_STATE=existing
    _ENV=$ETCD_DATA_DIR/etcd.env
    CLUSTER_ENDPOINT=http://$CLUSTER_LEAD:$CLIENT_PORT

    # This seems pretty fragile, but etcdctl has no stable cmdline method of getting the cluster variables.
    if ! test -s $_ENV
    then
        for i in 1 1 2 3 5 8 13 21 34 55; do
            etcdctl --no-sync --endpoint $CLUSTER_ENDPOINT member add $ETCD_NAME http://$IP_ADDRESS:$PEER_PORT | grep '^ETCD_' >$_ENV
            test -s $_ENV && break
            echo "SLEEPING for $i seconds before next attempt to join cluster"
            sleep $i
        done

        if ! test -s $_ENV
        then
            echo "ERROR: Never got ETCD_ variables from etcdctl member add"
            exit 1
        fi
    fi

    set -a
    . $_ENV
    set +a
fi

export ETCD_LISTEN_CLIENT_URLS=http://$LISTEN_IP_ADDRESS:$CLIENT_PORT
export ETCD_LISTEN_PEER_URLS=http://$LISTEN_IP_ADDRESS:$PEER_PORT
export ETCD_ADVERTISE_CLIENT_URLS=http://$IP_ADDRESS:$CLIENT_PORT
export ETCD_INITIAL_ADVERTISE_PEER_URLS=http://$IP_ADDRESS:$PEER_PORT

exec etcd
