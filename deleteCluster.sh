#!/usr/bin/env bash

cluster_name="${1:-kind}"

kind delete cluster --name "${cluster_name}"
