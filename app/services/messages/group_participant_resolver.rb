# frozen_string_literal: true

# Resolves the individual sender included in group-message prefixes received by API inboxes.
class Messages::GroupParticipantResolver
  PREFIX_PATTERN = /\A\*\*\s*(?<phone>\+?[\d\s().-]{7,32}?)\s+-\s+(?<name>[^:\r\n]+):\*\*/.freeze
  MIN_PHONE_DIGITS = 7
  MAX_PHONE_DIGITS = 15

  def self.resolve_all(messages)
    candidates = Array(messages).filter_map do |message|
      participant = participant_from(message)
      [message, participant] if participant
    end
    return if candidates.empty?

    candidates.group_by { |message, _participant| message.account_id }.each do |account_id, account_candidates|
      resolve_account_candidates(account_id, account_candidates)
    end
  end

  def self.resolve(message)
    return unless participant_from(message)

    resolve_all([message])
    message.sender_data
  end

  def self.participant_from(message)
    return unless message.incoming? && message.inbox&.api?

    match = message.content.to_s.match(PREFIX_PATTERN)
    return unless match

    phone = match[:phone].gsub(/\D/, '')
    return unless phone.length.between?(MIN_PHONE_DIGITS, MAX_PHONE_DIGITS)

    { phone: phone, name: match[:name].strip }
  end
  private_class_method :participant_from

  def self.resolve_account_candidates(account_id, candidates)
    phones = candidates.map { |_message, participant| participant[:phone] }.uniq
    contacts = Contact.where(account_id: account_id, phone_number: phones.map { |phone| "+#{phone}" })
                      .includes(avatar_attachment: :blob)
    contacts_by_phone = contacts.index_by { |contact| contact.phone_number.to_s.gsub(/\D/, '') }

    candidates.each do |message, participant|
      contact = contacts_by_phone[participant[:phone]]
      sender_data = if contact
                      contact.push_event_data.merge(
                        name: contact.name.presence || participant[:name],
                        group_participant: true
                      )
                    else
                      {
                        name: participant[:name],
                        phone_number: "+#{participant[:phone]}",
                        thumbnail: '',
                        type: 'contact',
                        group_participant: true
                      }
                    end

      message.sender_data = sender_data
    end
  end
  private_class_method :resolve_account_candidates
end
