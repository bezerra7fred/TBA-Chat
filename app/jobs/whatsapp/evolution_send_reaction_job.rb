class Whatsapp::EvolutionSendReactionJob < ApplicationJob
  queue_as :default

  def perform(message_id, reaction)
    message = Message.find_by(id: message_id)
    return if message.nil?

    Whatsapp::EvolutionReactionService.new(message: message, reaction: reaction).perform
  end
end
