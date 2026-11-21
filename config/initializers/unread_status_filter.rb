# Support unread conversation status. The frontend option is compiled from source;
# do not mutate fingerprinted Vite files or their manifest during Rails startup.
module UnreadStatusFilterPatch
  UNREAD_EXISTS_CLAUSE =
    'EXISTS (SELECT 1 FROM messages WHERE messages.conversation_id = conversations.id ' \
    'AND messages.account_id = conversations.account_id ' \
    'AND messages.message_type = 0 ' \
    'AND (conversations.agent_last_seen_at IS NULL OR messages.created_at > conversations.agent_last_seen_at))'.freeze

  def filter_by_status
    return @conversations = @conversations.where(UNREAD_EXISTS_CLAUSE) if params[:status].to_s == 'unread'

    super
  end
end

Rails.application.config.to_prepare do
  ConversationFinder.prepend(UnreadStatusFilterPatch) unless ConversationFinder <= UnreadStatusFilterPatch
end
