class Microsoft::OutlookCallbacksController < ApplicationController
  def show
    user = User.find_signed!(params[:state], purpose: :personal_outlook)
    token = microsoft_client.auth_code.get_token(params[:code], redirect_uri: callback_url)
    save_connection(user, token.to_hash)
    redirect_to profile_url(user)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, JWT::DecodeError, KeyError, OAuth2::Error
    redirect_to ENV.fetch('FRONTEND_URL', request.base_url), alert: I18n.t('personal_outlook.connection_failed')
  end

  private

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

  def save_connection(user, token_data)
    identity = JWT.decode(token_data.fetch(:id_token), nil, false).first
    user.personal_outlook_connection&.destroy!
    user.create_personal_outlook_connection!(
      email: identity['preferred_username'] || identity['email'],
      refresh_token: token_data.fetch(:refresh_token),
      expires_at: Time.zone.at(token_data.fetch(:expires_at))
    )
  end

  def profile_url(user)
    account_id = user.account_users.order(active_at: :desc).pick(:account_id)
    return ENV.fetch('FRONTEND_URL', request.base_url) unless account_id

    "#{ENV.fetch('FRONTEND_URL', request.base_url)}/app/accounts/#{account_id}/profile/settings"
  end
end
