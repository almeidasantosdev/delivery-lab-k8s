# ADR 001: Kubernetes em outro repositorio

O Delivery Lab ja descreve a aplicacao, a imagem e a infraestrutura na AWS. Este repositorio so descreve como essa mesma imagem roda num cluster local.

Kind e k3s sobem na maquina de quem clona o projeto. Nao ha Terraform, VPC nem bucket aqui. A imagem continua sendo construida a partir de [delivery-lab](https://github.com/almeidasantosdev/delivery-lab). Ela nao e publicada num registro.

Os manifestos da aplicacao ficam no chart `charts/delivery-lab`. O arquivo do Kind e o metrics-server ficam fora do chart, porque nao fazem parte da release. A API e o worker usam a mesma imagem, com comandos diferentes: `node dist/main.js` e `node dist/worker-main.js`.

A publicacao externa no OpenShift fica com `oc expose`, fora do chart, porque o laboratorio local usa a porta do no.
