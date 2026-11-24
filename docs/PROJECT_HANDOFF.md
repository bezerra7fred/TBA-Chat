# Handoff do projeto TBA-Chat

Atualizado em 2026-11-24. Este arquivo registra o estado confirmado para a próxima sessão/agente.

## Repositório e instruções

- Repositório: https://github.com/bezerra7fred/TBA-Chat
- Base confirmada: `origin/main` em `ed7f432a91` (`fix(microsoft): use tenant-specific OAuth authority`).
- É um fork customizado do Chatwoot. Leia `AGENTS.md` antes de alterar código e siga o prefixo `rtk` para comandos de shell compatíveis.
- O checkout principal local estava em uma branch antiga e sem alterações locais; o handoff foi preparado em uma branch isolada baseada no `origin/main`.

## Estado confirmado

### Outlook individual

- A funcionalidade de caixa pessoal foi adicionada ao perfil do usuário: autenticação Microsoft e conexão individual por usuário, com leitura via IMAP e envio via SMTP.
- A correção para usar autoridade OAuth específica do tenant está em `main` no commit `ed7f432a91`.
- O login de produção chegou à Microsoft, mas terminou em **“Necessidade de aprovação de administrador”** para o aplicativo **TBA-Chat Outlook**. A conta usada não é administradora do tenant.
- Portanto, a caixa ainda **não está conectada**: não foi concluído consentimento OAuth nem criado token/conexão utilizável.
- O fluxo solicitou permissões delegadas para IMAP (`IMAP.AccessAsUser.All`) e SMTP (`SMTP.Send`), além de `offline_access` e escopos de identidade. O administrador do Microsoft 365 precisa aprovar o aplicativo no tenant; não tentar contornar essa política.
- Depois da aprovação, retomar o login no navegador interno do Codex e validar entrada e envio de mensagens. A preferência é que cada pessoa conecte sua própria caixa.

### Reações e identidade visual

- Há alterações de reações na linha principal: atribuição de reações a pessoas, correção de limites do popup e rótulo mais claro no botão.
- A correção de autoridade do tenant e a caixa Outlook individual estão presentes no histórico recente de `main`; conferir o comportamento implantado separadamente do código do repositório.

### CI

- CircleCI foi escolhido como pipeline a usar.
- A árvore atual de `main` ainda contém workflows em `.github/workflows`, incluindo `nightly_installer.yml`, `test_docker_build.yml`, `run_foss_spec.yml` e `tba-frontend-build.yml`. Logo, “somente CircleCI” ainda não está refletido literalmente na árvore.
- Em uma resposta anterior, o usuário aceitou manter temporariamente no GitHub o build manual e o instalador noturno; depois reiterou “somente CircleCI”. Confirme o escopo atual antes de declarar a migração concluída ou remover workflows.

## Produção e acesso

- A instância está no Azure. Em sessões anteriores, os diagnósticos foram feitos pelo Azure Cloud Shell com Run Command; o SSH direto falhou por chave pública.
- Um registro anterior reportou centenas de alterações pré-existentes no checkout do servidor (cerca de 682). **Verifique o estado atual antes de qualquer deploy**; não faça reset, checkout destrutivo nem substitua o diretório.
- Foi relatado anteriormente que somente o patch da autoridade Microsoft foi aplicado diretamente no servidor e o serviço web reiniciado; isso não confirma que toda a funcionalidade Outlook de `main` esteja implantada. Revalidar versão e arquivos no servidor antes de prosseguir.
- Não registrar neste repositório chaves SSH, tokens, segredos OAuth, valores de `state` ou credenciais.

## Próximos passos

1. Aguardar o administrador conceder consentimento ao aplicativo **TBA-Chat Outlook** para as permissões IMAP e SMTP solicitadas.
2. Retomar o OAuth da conta pessoal, verificar se IMAP e SMTP ficam ativos e testar recebimento e envio.
3. Verificar com segurança se o código completo da integração está implantado em produção; preservar alterações existentes no servidor.
4. Reconciliar a instrução mais recente de CircleCI-only com os workflows de GitHub Actions ainda presentes e registrar a decisão final.

## Preferências de colaboração

- Conversar em português e avançar proativamente.
- Quando uma página web for necessária, usar a aba interna do Codex.
- Evitar pedir novamente informações já dadas; pedir intervenção do usuário somente quando uma aprovação administrativa ou ação na conta dele for necessária.
