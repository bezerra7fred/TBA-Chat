require 'net/imap'
require 'mail'

class PersonalOutlook::MailboxService
  IMAP_ADDRESS = 'outlook.office365.com'.freeze
  PAGE_SIZE = 25

  def initialize(connection)
    @connection = connection
  end

  def messages(folder: 'inbox')
    with_imap do |imap|
      mailbox = folder == 'sent' ? sent_mailbox(imap) : 'INBOX'
      imap.select(mailbox)
      uids = imap.uid_search(['ALL']).last(PAGE_SIZE).reverse
      imap.uid_fetch(uids, ['ENVELOPE', 'BODY.PEEK[]']).filter_map do |fetch|
        serialize_message(fetch)
      end
    end
  end

  private

  def with_imap
    imap = Net::IMAP.new(IMAP_ADDRESS, port: 993, ssl: true)
    imap.authenticate('XOAUTH2', @connection.email, access_token)
    yield imap
  ensure
    imap&.disconnect
  end

  def access_token
    return @access_token if @connection.expires_at > 5.minutes.from_now

    client = OAuth2::Client.new(
      GlobalConfigService.load('AZURE_APP_ID', nil),
      GlobalConfigService.load('AZURE_APP_SECRET', nil),
      site: 'https://login.microsoftonline.com',
      authorize_url: 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
      token_url: 'https://login.microsoftonline.com/common/oauth2/v2.0/token'
    )
    token = OAuth2::AccessToken.new(client, nil, refresh_token: @connection.refresh_token).refresh!
    @connection.update!(refresh_token: token.refresh_token, expires_at: Time.zone.at(token.expires_at))
    token.token
  end

  def sent_mailbox(imap)
    mailboxes = imap.list('', '*')
    mailbox = mailboxes.find { |entry| entry.attr.include?(:Sent) }
    mailbox ||= mailboxes.find { |entry| entry.name.match?(/sent|enviad/i) }
    mailbox&.name || 'Sent Items'
  end

  def serialize_message(fetch)
    raw_message = fetch.attr['BODY[]']
    return unless raw_message

    message = Mail.new(raw_message)
    {
      id: fetch.attr['UID'],
      subject: message.subject,
      from: message.from&.first,
      date: message.date,
      body: (message.text_part&.decoded || message.body.decoded).truncate(10_000)
    }
  end
end
