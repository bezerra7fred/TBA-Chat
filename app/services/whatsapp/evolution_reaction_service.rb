require 'net/http'
require 'json'
require 'uri'

class Whatsapp::EvolutionReactionService
  ALLOWED_KEY_FIELDS = %w[id remoteJid fromMe participant remoteJidAlt addressingMode].freeze
  SOURCE_ID_PREFIX = 'WAID:'
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 10

  def initialize(message:, reaction:)
    @message = message
    @reaction = reaction.to_s
  end

  def perform
    return false unless configured?
    return false if whatsapp_message_id.blank?

    key = original_key || fallback_key
    if key.blank?
      Rails.logger.warn("[EvolutionReaction] skipped message=#{message.id}: WhatsApp key not found")
      return false
    end

    response = post("/message/sendReaction/#{instance}", key: key, reaction: reaction)
    success = response.is_a?(Net::HTTPSuccess)
    log_result(response, success)
    success
  rescue StandardError => e
    Rails.logger.error("[EvolutionReaction] message=#{message&.id} failed: #{e.class}")
    false
  end

  private

  attr_reader :message, :reaction

  def configured?
    return true if api_url.present? && api_key.present? && instance.present?

    Rails.logger.warn(
      '[EvolutionReaction] skipped: EVOLUTION_API_URL/EVOLUTION_API_KEY/EVOLUTION_INSTANCE not configured'
    )
    false
  end

  def api_url
    ENV.fetch('EVOLUTION_API_URL', '').to_s.chomp('/')
  end

  def api_key
    ENV.fetch('EVOLUTION_API_KEY', '').to_s
  end

  def instance
    ENV.fetch('EVOLUTION_INSTANCE', '').to_s
  end

  def whatsapp_message_id
    source_id = message.source_id.to_s
    return unless source_id.start_with?(SOURCE_ID_PREFIX)

    source_id.delete_prefix(SOURCE_ID_PREFIX)
  end

  def original_key
    response = post("/chat/findMessages/#{instance}", where: { key: { id: whatsapp_message_id } })
    return nil unless response.is_a?(Net::HTTPSuccess)

    payload = JSON.parse(response.body.to_s)
    record = Array(payload.dig('messages', 'records')).find do |item|
      item.dig('key', 'id').to_s == whatsapp_message_id
    end
    normalize_key(record&.dig('key'))
  rescue JSON::ParserError
    Rails.logger.warn("[EvolutionReaction] invalid findMessages response message=#{message.id}")
    nil
  end

  def fallback_key
    remote_jid = message.conversation.contact&.identifier.to_s
    return nil if remote_jid.blank?

    key = {
      id: whatsapp_message_id,
      remoteJid: remote_jid,
      fromMe: message.outgoing?
    }
    participant = participant_jid
    key[:participant] = participant if participant.present?
    key
  end

  def participant_jid
    return nil unless message.conversation.contact&.identifier.to_s.end_with?('@g.us')
    return nil unless message.sender.is_a?(Contact)

    identifier = message.sender.identifier.to_s
    identifier if identifier.end_with?('@s.whatsapp.net', '@lid')
  end

  def normalize_key(key)
    return nil unless key.is_a?(Hash) && key['id'].present? && key['remoteJid'].present?

    key.slice(*ALLOWED_KEY_FIELDS).delete_if { |_field, value| value.nil? || value == '' }
  end

  def post(path, payload)
    uri = URI.parse("#{api_url}#{path}")
    raise URI::InvalidURIError unless %w[http https].include?(uri.scheme) && uri.host.present?

    request = Net::HTTP::Post.new(uri.request_uri)
    request['apikey'] = api_key
    request['Content-Type'] = 'application/json'
    request.body = payload.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = OPEN_TIMEOUT
    http.read_timeout = READ_TIMEOUT
    http.request(request)
  end

  def log_result(response, success)
    status = response.respond_to?(:code) ? response.code : 'no-response'
    level = success ? :info : :error
    Rails.logger.public_send(level, "[EvolutionReaction] message=#{message.id} status=#{status} success=#{success}")
  end
end
