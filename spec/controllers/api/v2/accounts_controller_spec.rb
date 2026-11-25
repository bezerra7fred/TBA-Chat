require 'rails_helper'

RSpec.describe 'Accounts API', type: :request do
  describe 'POST /api/v2/accounts' do
    let(:email) { Faker::Internet.email }

    it 'blocks public account creation and responds with 404' do
      params = { email: email, user: nil, locale: nil, password: 'Password1!' }

      post api_v2_accounts_url,
           params: params,
           as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
