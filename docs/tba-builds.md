# TBA Chat: builds fora da produção

Para alterações que precisam de build ou apresentam risco de esgotar a RAM do servidor, usar o workflow **TBA frontend build** no GitHub Actions. Não é necessário Docker nem compilar no PC. Alterações leves que não precisam de build não devem dispará-lo.

## Executar

No GitHub: Actions → TBA frontend build → Run workflow → selecionar a branch. Via CLI:

```sh
gh workflow run tba-frontend-build.yml --repo bezerra7fred/TBA-Chat --ref main
gh run list --repo bezerra7fred/TBA-Chat --workflow tba-frontend-build.yml
gh run download RUN_ID --repo bezerra7fred/TBA-Chat --name tba-frontend-COMMIT_SHA --dir staging
```

O workflow instala as versões do lockfile, executa os testes existentes de formatação de mensagens e compila Vite e SDK. Não inicia Rails, banco ou Redis; não executa migrações. Não é um teste completo da aplicação nem substitui compilação de assets Rails quando estes forem alterados.

## Segurança e custo

- Acionamento manual, tempo máximo de 35 minutos e apenas um build por branch em execução.
- Permissão `contents: read`, sem chave SSH ou `.env` de produção no runner.
- Pacote privado vinculado ao commit, com `build.json` e SHA-256.
- Apenas `public/vite` e os três arquivos `public/packs/js/sdk.js*` são empacotados.
- Artefato expira em 1 dia. Manter a franquia de armazenamento e processamento sob observação.
- A configuração de orçamento/bloqueio de gastos fica no faturamento da conta GitHub; este workflow não altera essa configuração e não garante custo zero por si só.

## Envio ao servidor

O build **não implanta automaticamente**. Após sucesso, o operador/agente baixa o pacote usando GitHub CLI e transfere por SSH autenticado para uma pasta de preparação no servidor, sem compilar nele. Conferir SHA-256 e o commit antes de publicar. Nunca usar chaves do projeto ou segredos dentro do pacote.

Antes da primeira implantação, comparar as personalizações existentes em produção com o commit: a working tree do servidor não é necessariamente idêntica ao GitHub. Não sobrescrever personalizações nem executar `git reset --hard`.

Preservar fontes anteriores, Vite completo/manifest e os três arquivos SDK como conjunto de recuperação. Não substituir todo `public/packs`: ele pode conter assets de marca personalizados. Manter assets antigos disponíveis para sessões abertas. Validar sintaxe Ruby/ERB, saúde HTTP, login, workers e envio/recebimento de mensagens após atualizar. Se necessário, recuperar o conjunto anterior. Atualizações de banco exigem backup e plano separado: Git não recupera dados nem necessariamente desfaz migrações.

O processo de transferência, ativação e rollback precisa ser validado antes de ser automatizado. O primeiro build é apenas de validação, sem alterações em produção.
