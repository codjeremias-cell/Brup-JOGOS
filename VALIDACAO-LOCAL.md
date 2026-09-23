# Validacao local e uso do GitHub

Decisao do dono em 22/09/2026: evitar duplicacao entre a maquina local e os runners do GitHub.

Use Godot 4.3-stable da plataforma local. Execute godot --headless --path . --import e, somente após sucesso, godot --headless --path . --script res://tools/run_tests.gd. Ajuste godot para o caminho real do executável instalado. O binário Linux baixado pelo workflow não é necessário no computador Windows.

## Regras de entrega

- Validar a versao final localmente uma vez; registrar commit ou diff, comandos, resultados e limites na PR/registro. Mudanca relevante exige nova validacao; sem mudanca nao repetir por rotina.
- Nenhuma execucao de teste na nuvem e obrigatoria pelo GitHub neste fluxo. Workflows mantidos servem apenas a diagnostico manual autorizado e podem consumir franquia.
- Nao enviar status ficticio de CI verde. A evidencia e local; ausencia de runner remoto e esperada.
- Desativar testes automaticos nao altera hospedagem, deploy externo, alertas de seguranca ou atualizacoes do Dependabot.
- Checks manuais nao foram executados para esta transicao. Foram validados localmente o YAML, a remocao dos gatilhos e a preservacao dos jobs. Alteracoes de aplicacao exigem seus testes antes de publicar.

## Protecao contra branches antigas

Os workflows de validacao foram tambem desativados na configuracao do GitHub. Isso impede que branches/PRs antigas, ainda com o YAML anterior, disparem testes. Para diagnostico remoto autorizado, reabilite somente o workflow necessario e use a versao atual de workflow_dispatch; desative-o novamente ao terminar. Nao usar branches antigas com gatilhos automaticos para esse diagnostico. O bot de capas do Fluxonar foi aposentado em favor da geracao local.
