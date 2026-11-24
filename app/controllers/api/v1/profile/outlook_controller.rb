class Api::V1::Profile::OutlookController < Api::BaseController
  def show
    render json: { connected: connection.present?, email: connection&.email }
  end

  def authorization
    client = microsoft_client
    url = client.auth_code.authorize_url(
      redirect_uri: callback_url,
      scope: 'offline_access https://outlook.office.com/IMAP.AccessAsUser.All openid profile email',
      state: current_user.signed_id(purpose: :personal_outlook, expires_in: 10.minutes),
      prompt: 'select_account'
    )
    render json: { url: url }
  end

  def messages
    folder = params.fetch(:folder, 'inbox')
    return render json: { error: 'Invalid folder' }, status: :unprocessable_entity unless %w[inbox sent].include?(folder)

    render json: { messages: PersonalOutlook::MailboxService.new(connection!).messages(folder: folder) }
  end

  def destroy
    connection&.destroy!
    head :no_content
  end

  private

  def connection
    @connection ||= current_user.personal_outlook_connection
  end

  def connection!
    connection || raise(ActiveRecord::RecordNotFound)
  end

  def microsoft_client
    ::OAuth2::Client.new(
      GlobalConfigService.load('AZURE_APP_ID', nil),
      GlobalConfigService.load('AZURE_APP_SECRET', nil),
      site: 'https://login.microsoftonline.com',
      authorize_url: 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
      token_url: 'https://login.microsoftonline.com/common/oauth2/v2.0/token'
    )
  end

  def callback_url
    "#{ENV.fetch('FRONTEND_URL', request.base_url)}/microsoft/outlook/callback"
  end
end
