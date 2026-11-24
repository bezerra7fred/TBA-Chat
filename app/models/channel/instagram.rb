# == Schema Information
#
# Table name: channel_instagram
#
#  id           :bigint           not null, primary key
#  access_token :string           not null
#  expires_at   :datetime         not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#  instagram_id :string           not null
#
# Indexes
#
#  index_channel_instagram_on_instagram_id  (instagram_id) UNIQUE
#
class Channel::Instagram < ApplicationRecord
  include Channelable
  include Reauthorizable
  self.table_name = 'channel_instagram'

  # TODO: Remove guard once encryption keys become mandatory (target 3-4 releases out).
  encrypts :access_token if Chatwoot.encryption_configured?

  AUTHORIZATION_ERROR_THRESHOLD = 1

  validates :access_token, presence: true
  validates :instagram_id, uniqueness: true, presence: true

  after_create_commit :subscribe
  before_destroy :unsubscribe

  def name
    'Instagram'
  end

  def create_contact_inbox(instagram_id, name)
    @contact_inbox = ::ContactInboxWithContactBuilder.new({
                                                            source_id: instagram_id,
                                                            inbox: inbox,
                                                            contact_attributes: { name: name }
                                                          }).perform
  end

  def subscribe
    # ref https://developers.facebook.com/docs/instagram-platform/webhooks#enable-subscriptions
    HTTParty.post(
      "#{base_uri}/#{instagram_id}/subscribed_apps",
      query: {
        subscribed_fields: %w[messages message_reactions messaging_seen],
        access_token: access_token
      }
    )
  rescue StandardError => e
    Rails.logger.debug { "Rescued: #{e.inspect}" }
    true
  end

  def unsubscribe
    HTTParty.delete(
      "#{base_uri}/#{instagram_id}/subscribed_apps",
      query: {
        access_token: access_token
      }
    )
    true
  rescue StandardError => e
    Rails.logger.debug { "Rescued: #{e.inspect}" }
    true
  end

  def access_token
    Instagram::RefreshOauthTokenService.new(channel: self).access_token
  end

  def send_reaction(contact_psid, message, emoji)
    return false if contact_psid.blank? || message.blank? || access_token.blank?

    message_mid = message.source_id
    return false if message_mid.blank? || !message_mid.is_a?(String)

    url = "https://graph.facebook.com/v18.0/me/messages"
    payload = {
      recipient: { id: contact_psid },
      sender_action: 'react',
      payload: emoji.to_s,
      mid: message_mid
    }

    response = HTTParty.post(url, query: { access_token: access_token }, body: payload.to_json, headers: { 'Content-Type' => 'application/json' }, timeout: 10)
    response.success?
  rescue StandardError => e
    Rails.logger.error "[INSTAGRAM] Failed to send reaction: #{e.message}"
    false
  end

  def remove_reaction(contact_psid, message, emoji)
    return false if contact_psid.blank? || message.blank? || access_token.blank?

    message_mid = message.source_id
    return false if message_mid.blank? || !message_mid.is_a?(String)

    url = "https://graph.facebook.com/v18.0/me/messages"
    payload = {
      recipient: { id: contact_psid },
      sender_action: 'unreact',
      payload: { message_id: message_mid }
    }

    response = HTTParty.post(url, query: { access_token: access_token }, body: payload.to_json, headers: { 'Content-Type' => 'application/json' }, timeout: 10)
    response.success?
  rescue StandardError => e
    Rails.logger.error "[INSTAGRAM] Failed to remove reaction: #{e.message}"
    false
  end

  private

  def base_uri
    "https://graph.instagram.com/#{GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')}"
  end
end
