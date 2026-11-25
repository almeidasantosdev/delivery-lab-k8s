$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$lab = if ($env:DELIVERY_LAB) { $env:DELIVERY_LAB } else { Join-Path (Split-Path -Parent $root) "delivery-lab" }
$dockerfile = Join-Path $lab "docker\Dockerfile"

if (-not (Test-Path $dockerfile)) {
  throw "Nao achei o Dockerfile em $lab. Clone https://github.com/almeidasantosdev/delivery-lab ou defina DELIVERY_LAB."
}

foreach ($cmd in @("docker", "kind", "kubectl", "helm")) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
    throw "Falta o comando $cmd."
  }
}

docker build -t delivery-lab:local -f $dockerfile $lab
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$clusters = @(kind get clusters)
if ($clusters -notcontains "delivery") {
  kind create cluster --config (Join-Path $root "kind\cluster.yaml")
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

kind export kubeconfig --name delivery
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

kind load docker-image delivery-lab:local --name delivery
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

helm upgrade --install delivery (Join-Path $root "charts\delivery-lab") --namespace delivery --create-namespace --wait --timeout 10m
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

kubectl apply -f (Join-Path $root "kind\metrics-server.yaml")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

kubectl -n kube-system rollout status deploy/metrics-server --timeout=180s
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "API em http://localhost:3000/health"
Write-Host "Worker: kubectl -n delivery port-forward svc/worker 3001:3001"
