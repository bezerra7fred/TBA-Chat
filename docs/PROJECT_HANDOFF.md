# Handoff do projeto TBA-Chat

Atualizado em 2026-11-24. Este documento resume o contexto de projeto necessário para a próxima sessão/agente; não substitui o histórico completo nem contém segredos.

## Repositório e instruções

- Repositório: https://github.com/bezerra7fred/TBA-Chat
- Base confirmada: `origin/main` em `ed7f432a91` (`fix(microsoft): use tenant-specific OAuth authority`).
- É um fork customizado do Chatwoot. Leia `AGENTS.md` antes de alterar código e siga o prefixo `rtk` para comandos de shell compatíveis.
- O trabalho deste handoff está numa branch isolada baseada no `origin/main`; não confundir com branches antigas no checkout original.
- Preferências do usuário: conversar em português, avançar proativamente e usar a aba interna do Codex quando precisar abrir navegador.

## Funcionalidades e estado do produto

### Outlook individual

- Foi adicionada ao perfil do usuário uma conexão de caixa pessoal Microsoft, com autenticação OAuth e leitura via IMAP/envio via SMTP.
- A preferência é cada pessoa conectar sua própria caixa. O usuário quer receber e enviar mensagens.
- A correção para autoridade OAuth específica do tenant está em `main` no commit `ed7f432a91`.
- O login de produção chegou à Microsoft, mas terminou em **“Necessidade de aprovação de administrador”** para o aplicativo **TBA-Chat Outlook**. A conta usada não é administradora do tenant.
- A caixa ainda **não está conectada**: não houve consentimento OAuth concluído nem token/conexão utilizável.
- Escopos solicitados: `IMAP.AccessAsUser.All`, `SMTP.Send`, `offline_access` e escopos de identidade. O administrador do Microsoft 365 precisa aprovar o aplicativo no tenant; não tentar contornar essa política.
- Próximo passo após a aprovação: retomar o OAuth na aba interna do Codex, confirmar que IMAP e SMTP ficam ativos e testar recebimento e envio.

### Reações e marca

- Alterações recentes na linha principal incluem mostrar quem reagiu, manter o seletor de emoji dentro da tela e trocar o botão “+” por um rótulo mais claro (“Reagir”).
- Também há uma correção de título da aba/favicon para “TBA Chat” no histórico da linha principal.
- Código presente no Git não garante que essas versões estejam em produção; validar o servidor separadamente.

### Lista de empresas

- O usuário pediu incluir **AMVALI** e também: AM CONTABILIDADE; CEJAS_ACIJS_CDL_APEVI; DESENTUPIDORA CARVALHO; DIBRASA; DOCEMEL; ELETROFRIO; ELIAN; ESPAÇO SMART; ESTUDIOSEE; FSF (FRATERNIDADE SEM FRONTEIRA); GLOBAL; GRADUAL; GRUPO SEGURA; JCH REPRESENTAÇÕES; JJD ARQUITETURA; KRAPPER EIKON; KWB; LUCATHI COMMERCE; PKI CONSULTING; POLUX; PONTUAL MEDIC; PORTO E LEMKE; POSTO MARTENDAL; PRESTICOM; PROMA; RAUMAK; REDE M7; SANTANTONIO; SMART REPRESENTAÇÕES; STEELMAST; TEXTILFIO; TRITEC; ZOVENO.
- Não localizei `AMVALI` nos diretórios `app`, `config` ou `db` da base atual. Verifique se a lista é mantida em banco/produção ou em outra tela antes de afirmar que todas foram incluídas.

## WhatsApp via Evolution API — incidente em aberto

- O usuário relatou que novas mensagens de WhatsApp via Evolution API deixaram de chegar.
- Última fotografia diagnóstica: `CHATWOOT_ENABLED=true`; endpoint da integração Chatwoot respondeu HTTP 200, habilitado, conta e token configurados; inbox `whatsapp`; host-alvo `127.0.0.1:3000`; `webhookUrlConfigured=false`; importação de contatos e mensagens habilitada.
- Nos logs das últimas seis horas não apareceram eventos `messages.upsert` nem erros de webhook/integração pesquisados.
- Container Evolution API estava em `networkMode=host`; teste local retornou HTTP 301 e o host público HTTP 200.
- Causa ainda não foi determinada. Continuar verificando a configuração/entrega de eventos e o callback sem assumir que o HTTP 200 prova que as mensagens estão chegando.
- O usuário pediu explicitamente para **não desconectar/reconectar o WhatsApp nem gerar QR code**, pois não estava com o aparelho da empresa.

## RTK e acesso ao servidor

- RTK foi escolhido para reduzir consumo de tokens; o usuário informou que o instalou no servidor.
- Uma execução por Azure Run Command respondeu `rtk: not found`. Isso mostra que o binário não estava no PATH do script não interativo, não necessariamente que a instalação inexista.
- Diagnósticos anteriores foram feitos via Azure Cloud Shell/Run Command na VM `chatwoot-sv`, grupo `CHATWOOT`. SSH direto falhou por chave pública.
- Um registro anterior reportou cerca de 682 alterações pré-existentes no checkout do servidor. Reconfira o estado antes de qualquer deploy; não faça reset, checkout destrutivo nem substitua o diretório.
- Foi relatado que somente o patch da autoridade Microsoft foi aplicado diretamente no servidor e o serviço web reiniciado. Isso não confirma que toda a integração Outlook de `main` esteja implantada.
- Não incluir chaves SSH, tokens, segredos OAuth, valores de `state`, API keys ou credenciais neste repositório.

## CI e publicação

- O usuário decidiu usar CircleCI como CI/CD e sua instrução mais recente é **somente CircleCI**.
- A árvore atual de `main` ainda contém workflows em `.github/workflows`, incluindo `nightly_installer.yml`, `test_docker_build.yml`, `run_foss_spec.yml` e `tba-frontend-build.yml`. Portanto, a migração completa ainda não está refletida no repositório.
- Houve uma decisão anterior e temporária de manter build manual e instalador noturno no GitHub Actions; ela foi seguida pela instrução mais recente de usar somente CircleCI. Tratar a migração/remoção dos workflows restantes como pendência, sem declarar concluído antes da verificação.

## Próximos passos sugeridos

1. Obter consentimento administrativo para o aplicativo Outlook e validar uma sessão real de envio e recebimento.
2. Diagnosticar o fluxo de eventos/webhook da Evolution API sem desconectar a sessão do WhatsApp.
3. Confirmar onde a lista de empresas é mantida e verificar todos os nomes solicitados.
4. Migrar/desativar os workflows GitHub Actions restantes conforme a instrução CircleCI-only e validar os gatilhos resultantes.
5. Verificar com segurança a versão e o estado da produção; preservar as alterações existentes no servidor antes de qualquer implantação.
