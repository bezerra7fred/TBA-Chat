# Patch para exibir "Não lidas" no filtro básico de conversas (status) do Chatwoot
#
# O que faz:
# 1. Backend: faz ConversationFinder aceitar status=unread e filtrar apenas
#    conversas com mensagens recebidas (incoming) após o agent_last_seen_at.
# 2. Frontend (produção, sem rebuild do Vite): injeta a opção "Não lidas"
#    no dropdown de status (abertas/resolvidas/pendentes/adiadas/todas).
#    - O label usa o texto literal "Não lidas" (sem dependência de tradução
#      no bundle de locales, que também tem cache de 1 ano).
#    - Após patchar, gera uma cópia com hash novo no nome do arquivo e
#      atualiza o manifest.json, para burlar o cache agressivo do navegador
#      (Cache-Control: public, max-age=31556952) sem exigir Ctrl+Shift+R.
#
# O patch é idempotente e roda no boot do Rails (after_initialize), então
# sobrevive a updates da imagem chatwoot/chatwoot:latest (o hash do arquivo
# dashboard-*.js pode mudar, o padrão continua). Não roda no Sidekiq.

# encoding: utf-8

require 'json'
require 'digest'

module UnreadStatusFilterPatch
  UNREAD_EXISTS_CLAUSE =
    "EXISTS (SELECT 1 FROM messages WHERE messages.conversation_id = conversations.id " \
    "AND messages.account_id = conversations.account_id " \
    "AND messages.message_type = 0 " \
    "AND (conversations.agent_last_seen_at IS NULL OR messages.created_at > conversations.agent_last_seen_at))".freeze

  def filter_by_status
    if params[:status].to_s == 'unread'
      @conversations = @conversations.where(UNREAD_EXISTS_CLAUSE)
    else
      super
    end
  end
end

module UnreadStatusAssetPatch
  def self.patch!(logger)
    vite_root = Rails.root.join('public', 'vite')
    assets_dir = vite_root.join('assets')
    manifest_path = vite_root.join('.vite', 'manifest.json')
    return if !Dir.exist?(assets_dir) || !File.exist?(manifest_path)

    # --- 1) Tradução no bundle de locales (best-effort, sem renomear o chunk) ---
    Dir.glob(assets_dir.join('*.js')).each do |file|
      begin
        content = File.read(file, encoding: 'UTF-8')
        next if content.empty?
        next unless content.include?('CHAT_STATUS_FILTER_ITEMS:{open:')

        original = content
        patched = content.gsub(
          /(CHAT_STATUS_FILTER_ITEMS:\{open:\{TEXT:"[^"]+"\},resolved:\{TEXT:"[^"]+"\},pending:\{TEXT:"[^"]+"\},snoozed:\{TEXT:"[^"]+"\},all:\{TEXT:"[^"]+"\}\})/
        ) do |match|
          label = (match.include?('Abertas') || match.include?('Todas') || match.include?('Status')) ? 'Não lidas' : 'Unread'
          "#{match[0...-1]},unread:{TEXT:\"#{label}\"}}"
        end

        next if patched == original

        tmp = "#{file}.tmp-#{Process.pid}"
        File.write(tmp, patched, encoding: 'UTF-8')
        File.rename(tmp, file)
        logger.info "[UnreadStatusFilter] Patched (locales) #{File.basename(file)}"
      rescue StandardError => e
        logger.error "[UnreadStatusFilter] locales patch falhou em #{File.basename(file)}: #{e.class}: #{e.message}"
      end
    end

    # --- 2) Opção no dropdown + cache-busting do entrypoint dashboard ---
    manifest = JSON.parse(File.read(manifest_path, encoding: 'UTF-8'))
    entry_key = 'entrypoints/dashboard.js'
    entry = manifest[entry_key]
    return unless entry && entry['file']

    old_rel = entry['file'] # ex: "assets/dashboard-BqW1bkNo.js"
    old_path = vite_root.join(old_rel)
    return if !File.exist?(old_path)

    content = File.read(old_path, encoding: 'UTF-8')
    patched = content.dup

    # 2a) Se ainda sem a opção, adiciona com i18n (primeira vez / imagem nova)
    has_unread_status = patched.include?('CHAT_STATUS_FILTER_ITEMS.unread.TEXT') ||
                        patched.include?('"Não lidas",value:"unread"')
    if !has_unread_status
      patched = patched.gsub(
        /(\{label:(\w+)\("CHAT_LIST\.CHAT_STATUS_FILTER_ITEMS\.all\.TEXT"\),value:"all"\})/
      ) { "#{Regexp.last_match(1)},{label:#{Regexp.last_match(2)}(\"CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.unread.TEXT\"),value:\"unread\"}" }
    end

    # 2b) Converte label i18n para literal "Não lidas" (evita depender do bundle
    #     de locales, que também fica em cache por 1 ano).
    patched = patched.gsub(
      /\{label:\w+\("CHAT_LIST\.CHAT_STATUS_FILTER_ITEMS\.unread\.TEXT"\),value:"unread"\}/
    ) { '{label:"Não lidas",value:"unread"}' }

    if patched != content
      tmp = "#{old_path}.tmp-#{Process.pid}"
      File.write(tmp, patched, encoding: 'UTF-8')
      File.rename(tmp, old_path)
      content = patched
      logger.info "[UnreadStatusFilter] Patched (dropdown) #{File.basename(old_path)}"
    end

    # 2c) Cache-busting: cria cópia com hash novo e aponta o manifest p/ ela.
    #     Evita que o navegador continue usando o JS antigo (mesma URL + cache 1 ano).
    new_hash = Digest::SHA256.hexdigest(content)[0, 8]
    desired_name = "dashboard-#{new_hash}.js"
    current_name = File.basename(old_rel)
    if current_name != desired_name
      new_path = assets_dir.join(desired_name)
      if !File.exist?(new_path) || File.read(new_path, encoding: 'UTF-8') != content
        File.write(new_path, content, encoding: 'UTF-8')
        logger.info "[UnreadStatusFilter] Cache-busted: #{current_name} -> #{desired_name}"
      end
      manifest[entry_key]['file'] = "assets/#{desired_name}"
      tmp_m = "#{manifest_path}.tmp-#{Process.pid}"
      File.write(tmp_m, JSON.generate(manifest), encoding: 'UTF-8')
      File.rename(tmp_m, manifest_path)
      logger.info "[UnreadStatusFilter] Manifest atualizado para #{desired_name}"

      begin
        ViteRuby.instance.manifest.refresh if defined?(ViteRuby) && ViteRuby.respond_to?(:instance)
      rescue StandardError => e
        logger.warn "[UnreadStatusFilter] refresh Vite manifest ignorado: #{e.message}"
      end
    end
  rescue StandardError => e
    logger.error "[UnreadStatusFilter] Falha ao patchar assets do dashboard: #{e.class}: #{e.message}"
  end
end

Rails.application.config.after_initialize do
  # Backend: ConversationFinder com status=unread
  begin
    unless ConversationFinder.ancestors.include?(UnreadStatusFilterPatch)
      ConversationFinder.prepend(UnreadStatusFilterPatch)
      Rails.logger.info '[UnreadStatusFilter] ConversationFinder patch aplicado (status=unread)'
    end
  rescue NameError => e
    Rails.logger.error "Falha ao aplicar UnreadStatusFilterPatch: #{e.message}"
  end

  # Frontend: patch dos bundles compilados (somente processo web/Rails)
  begin
    sidekiq_process = $PROGRAM_NAME.to_s.include?('sidekiq') || (defined?(Sidekiq) && $0.to_s.include?('sidekiq'))
    UnreadStatusAssetPatch.patch!(Rails.logger) unless sidekiq_process
  rescue StandardError => e
    Rails.logger.error "Falha ao aplicar UnreadStatusAssetPatch: #{e.message}"
  end
end
