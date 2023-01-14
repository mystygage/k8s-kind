#!/usr/bin/env bash

cluster_name="${1:-kind}"

PS3='Please select a k8s version: '
options=("v1.20" "v1.25" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "v1.20")
            kindest_node_image="kindest/node:v1.20.15@sha256:a32bf55309294120616886b5338f95dd98a2f7231519c7dedcec32ba29699394"
            ingress_nginx_controller="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.1/deploy/static/provider/kind/1.20/deploy.yaml"
            break
            ;;
        "v1.25")
            kindest_node_image="kindest/node:v1.25.3@sha256:f52781bc0d7a19fb6c405c2af83abfeb311f130707a0e219175677e366cc45d1"
            ingress_nginx_controller="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/kind/deploy.yaml"
            break
            ;;
        "Quit")
            exit 0
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

echo "👷 Create k8s cluster ${opt} with cluster name ${cluster_name}"

kind create cluster \
  --image "${kindest_node_image}" \
  --name "${cluster_name}" \
  --config kind-config-k8s.yaml

echo "🚧 Install ingress-nginx ..."
kubectl apply -f "${ingress_nginx_controller}"

echo "⏳ Waiting for Ingress to be ready ..."

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

echo "⌛️ Cluster and Ingress available."

if ! command -v mkcert &> /dev/null
then
    echo "💁 mkcert could not be found, skipping cert-manager installation"
    echo "✅ k8s cluster kind-${cluster_name} is ready."
    exit 0
fi

echo "👷 Install cert-manager"
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.10.1/cert-manager.yaml

echo "🚧 Creating K8S secrets with the CA private keys (will be used by the cert-manager Cluster Issuer)"
CA_CERTS_FOLDER=$(mkcert -CAROOT)
kubectl --namespace cert-manager create secret tls mkcert-ca-key-pair \
  --key=${CA_CERTS_FOLDER}/rootCA-key.pem \
  --cert=${CA_CERTS_FOLDER}/rootCA.pem

echo "⏳ Waiting for Cert Manager Webhook to be ready ..."
kubectl wait --namespace cert-manager \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=webhook \
  --timeout=90s

kubectl apply -f cert-manager-cluster-issuer.yaml

echo "✅ k8s cluster kind-${cluster_name} is ready."
