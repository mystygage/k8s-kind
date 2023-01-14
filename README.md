# Local k8s cluster with kind

Kind runs a **k**8s cluster **in** **d**ocker.

## Basic setup

Please install and configure Kind as described here:
- [Installation](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [Kubeconfig](https://kind.sigs.k8s.io/docs/user/quick-start/#interacting-with-your-cluster)

Optional:
- [mkcert](https://github.com/FiloSottile/mkcert) for TLS

## Create a cluster

Create a k8s cluster (v1.20.15) with 3 nodes and nginx-ingress (v1.2.1):

```bash
./createCluster.sh [clusterName]
```

If `mkcert` is available, [cert-manager](https://cert-manager.io) with a CA Cluster Issuer named `ca-cluster-issuer` for mkcert CA will also be installed.

## Delete a cluster

Tear down the cluster with

```bash
./deleteCluster.sh [clusterName]
```

## Test Setup

There is a small configuration script to test the cluster, which will create
- a namespace `kind-test`
- a deployment/service/ingress for docker.io/mendhak/http-https-echo
- a deployment/service/ingress for docker.io/tomcat:9-jre17

```bash
kubectl apply -f test.yaml
```

### echo deployment

The reachability of the echo deployment can be tested with

```bash
curl localhost/foo
```

which should return `bar`.  

### tomcat pod

The tomcat is deployed without any webapps, so

```bash
curl localhost/tomcat
```

should return a `404`

### Cluster issuer

To test the `ca-cluster-issuer` you can use this configuration:

```bash
kubectl apply -f test-ca.yaml
```

Afterwards the above `curl` commands have to be executed with `https://<url>`
