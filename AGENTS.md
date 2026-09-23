## Decisao do dono — validacao local por padrao (22/09/2026)

Testes, lint, build e geracao de artefatos executam localmente antes de enviar/publicar. Nao repetir automaticamente na nuvem. Esta decisao substitui instrucoes anteriores que exigiam CI remoto verde; os criterios de qualidade e a aprovacao humana continuam. GitHub Actions de validacao somente manual, mediante necessidade e autorizacao explicita. Nao reativar push/pull_request/schedule para testes redundantes. Evidencia local precisa corresponder a versao final e registrar comandos/resultados; falha ou teste omitido nao aprova. Consulte [VALIDACAO-LOCAL.md](VALIDACAO-LOCAL.md).

