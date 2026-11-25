require 'rails_helper'
require 'base64'

RSpec.describe 'Enterprise Google OAuth attribution', type: :request do
  let(:email) { 'oauth-attribution@example.com' }
  let(:first_touch_cookie) { encoded_cookie('source' => 'reddit', 'source_type' => 'paid_social') }
  let(:last_touch_cookie) { encoded_cookie('source' => 'github', 'source_type' => 'referral') }

  before do
    allow(ChatwootApp).to receive(:enterprise?).and_return(true)
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google',
      uid: '123545',
      info: {
        name: 'OAuth Attribution',
        email: email,
        image: 'https://example.com/image.jpg'
      }
    )
  end

  it 'blocks Google OAuth signup even with marketing attribution cookies' do
    cookies[Internal::Accounts::MarketingAttributionService::FIRST_TOUCH_COOKIE] = first_touch_cookie
    cookies[Internal::Accounts::MarketingAttributionService::LAST_TOUCH_COOKIE] = last_touch_cookie

    with_modified_env ENABLE_ACCOUNT_SIGNUP: 'true', FRONTEND_URL: 'http://www.example.com' do
      expect do
        get '/omniauth/google_oauth2/callback'
        follow_redirect!
      end.not_to change(Account, :count)
    end

    expect(response).to redirect_to(%r{/app/login\?error=no-account-found$})
  end

  it 'returns an existing user to Shopify billing after Google OAuth' do
    create(:user, email: email)
    redirect_url = 'settings/billing?plan_handle=growth&shop=store.myshopify.com'

    with_modified_env FRONTEND_URL: 'http://www.example.com' do
      get '/omniauth/google_oauth2/callback', params: { state: redirect_url }
      follow_redirect!
    end

    query = URI.decode_www_form(URI.parse(response.location).query).to_h
    expect(query['redirect_url']).to eq(redirect_url)
    expect(query).to include('email', 'sso_auth_token')
  end

  it 'does not preserve an external URL from Google OAuth state' do
    create(:user, email: email)

    with_modified_env FRONTEND_URL: 'http://www.example.com' do
      get '/omniauth/google_oauth2/callback', params: { state: 'https://example.com/redirect' }
      follow_redirect!
    end

    query = URI.decode_www_form(URI.parse(response.location).query).to_h
    expect(query).not_to have_key('redirect_url')
  end

  def encoded_cookie(payload)
    Base64.urlsafe_encode64(payload.to_json, padding: false)
  end
end
