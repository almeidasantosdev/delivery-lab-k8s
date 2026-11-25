#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
lab=${DELIVERY_LAB:-"$(dirname "$root")/delivery-lab"}

if [ ! -f "$lab/docker/Dockerfile" ]; then
  echo "Nao achei o Dockerfile em $lab. Clone https://github.com/almeidasantosdev/delivery-lab ou defina DELIVERY_LAB." >&2
  exit 1
fi

for cmd in docker kind kubectl helm; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Falta o comando $cmd." >&2
    exit 1
  fi
done

docker build -t delivery-lab:local -f "$lab/docker/Dockerfile" "$lab"

if ! kind get clusters | grep -qx delivery; then
  kind create cluster --config "$root/kind/cluster.yaml"
fi

kind export kubeconfig --name delivery
kind load docker-image delivery-lab:local --name delivery

helm upgrade --install delivery "$root/charts/delivery-lab" \
  --namespace delivery \
  --create-namespace \
  --wait \
  --timeout 10m

kubectl apply -f "$root/kind/metrics-server.yaml"
kubectl -n kube-system rollout status deploy/metrics-server --timeout=180s

echo "API em http://localhost:3000/health"
echo "Worker: kubectl -n delivery port-forward svc/worker 3001:3001"
