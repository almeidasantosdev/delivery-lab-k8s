# Chart delivery-lab

Chart do laboratorio local. A explicacao de arquitetura, Kind, valores e CI esta no [README do repositorio](../../README.md).

```powershell
helm lint .\charts\delivery-lab
helm template delivery .\charts\delivery-lab --namespace delivery
helm upgrade --install delivery .\charts\delivery-lab --namespace delivery --create-namespace --wait --timeout 10m
```

Um namespace recebe uma release. Os nomes dos recursos sao fixos: `api`, `worker`, `postgres`, `rabbitmq`.

`api.enabled` e `worker.enabled` ligam ou desligam cada processo. O worker exige `rabbitmq.enabled`. Os dois processos exigem `postgres.enabled`.
