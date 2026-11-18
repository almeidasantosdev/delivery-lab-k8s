$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$lab = if ($env:DELIVERY_LAB) { $env:DELIVERY_LAB } else { Join-Path (Split-Path -Parent $root) "delivery-lab" }
$dockerfile = Join-Path $lab "docker\Dockerfile"

if (-not (Test-Path $dockerfile)) {
  throw "Nao achei o Dockerfile em $lab. Clone https://github.com/almeidasantosdev/delivery-lab ou defina DELIVERY_LAB."
}

docker build -t delivery-lab:local -f $dockerfile $lab
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$clusters = @(kind get clusters)
if ($clusters -notcontains "delivery") {
  kind create cluster --config (Join-Path $root "kind\cluster.yaml")
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

kind load docker-image delivery-lab:local --name delivery
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

kubectl apply -k (Join-Path $root "k8s")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

kubectl apply -f (Join-Path $root "kind\metrics-server.yaml")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

kubectl -n delivery rollout status deploy/postgres --timeout=180s
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

kubectl -n delivery rollout status deploy/api --timeout=180s
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "API em http://localhost:3000/health"
