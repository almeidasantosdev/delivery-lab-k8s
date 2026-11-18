#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
lab=${DELIVERY_LAB:-"$(dirname "$root")/delivery-lab"}

if [ ! -f "$lab/docker/Dockerfile" ]; then
  echo "Nao achei o Dockerfile em $lab. Clone https://github.com/almeidasantosdev/delivery-lab ou defina DELIVERY_LAB." >&2
  exit 1
fi

docker build -t delivery-lab:local -f "$lab/docker/Dockerfile" "$lab"

if ! kind get clusters | grep -qx delivery; then
  kind create cluster --config "$root/kind/cluster.yaml"
fi

kind load docker-image delivery-lab:local --name delivery
kubectl apply -k "$root/k8s"
kubectl apply -f "$root/kind/metrics-server.yaml"
kubectl -n delivery rollout status deploy/postgres --timeout=180s
kubectl -n delivery rollout status deploy/api --timeout=180s
echo "API em http://localhost:3000/health"
