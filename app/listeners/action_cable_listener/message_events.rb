module ActionCableListener::MessageEvents
  include Events::Types

  def message_created(event)
    message, account = extract_message_and_account(event)
    conversation = message.conversation
    tokens = user_tokens(account, conversation.inbox.members) + contact_tokens(conversation.contact_inbox, message)

    broadcast(account, tokens, MESSAGE_CREATED, message.push_event_data)
  end

  def message_updated(event)
    message, account = extract_message_and_account(event)
    conversation = message.conversation
    tokens = user_tokens(account, conversation.inbox.members) + contact_tokens(conversation.contact_inbox, message)

    broadcast(account, tokens, MESSAGE_UPDATED, message.push_event_data.merge(previous_changes: event.data[:previous_changes]))
  end

  def message_reactions_updated(event)
    message, account = extract_message_and_account(event)
    tokens = user_tokens(account, message.inbox.members)
    broadcast(account, tokens, MESSAGE_REACTIONS_UPDATED, {
                id: message.id,
                conversation_id: message.conversation.display_id,
                content_attributes: { reactions: message.content_attributes['reactions'] }
              })
  end
end
