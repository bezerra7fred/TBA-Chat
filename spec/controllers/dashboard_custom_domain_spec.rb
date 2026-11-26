require 'rails_helper'

describe 'GET / on a help center custom domain', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }

  around do |example|
    with_modified_env FRONTEND_URL: 'http://www.chatwoot.test' do
      example.run
    end
  end

  context 'when the portal uses the documentation layout' do
    let!(:portal) do
      create(:portal, account: account, slug: 'doc-portal', custom_domain: 'docs.example.com',
                      config: { allowed_locales: ['en'], default_locale: 'en', layout: 'documentation' })
    end
    let!(:category) do
      create(:category, name: 'Getting Started', portal: portal, account_id: account.id, locale: 'en', slug: 'getting-started')
    end

    before do
      create(:article, category: category, portal: portal, account: account, author: agent, locale: 'en', status: :published)
    end

    it 'redirects unauthenticated visitors to login' do
      host! portal.custom_domain
      get '/'

      expect(response).to redirect_to('http://www.chatwoot.test/app/login?redirect_url=%2Fhc%2Fdoc-portal%2Fen')
    end

    it 'renders the documentation home in place for authenticated members' do
      host! portal.custom_domain
      get '/', headers: agent.create_new_auth_token

      expect(response).to have_http_status(:success)
      expect(response.body).to include('sidebar-drawer-checkbox')
      expect(response.body).to include('Getting Started')
    end

    it 'forbids an authenticated user from another account' do
      other_account_user = create(:user, account: create(:account), role: :agent)
      host! portal.custom_domain

      get '/', headers: other_account_user.create_new_auth_token

      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when the portal uses the classic layout' do
    let!(:portal) do
      create(:portal, account: account, slug: 'classic-portal', custom_domain: 'classic.example.com',
                      config: { allowed_locales: ['en'], default_locale: 'en', layout: 'classic' })
    end

    it 'redirects unauthenticated visitors to login' do
      host! portal.custom_domain
      get '/'

      expect(response).to redirect_to('http://www.chatwoot.test/app/login?redirect_url=%2Fhc%2Fclassic-portal%2Fen')
    end

    it 'renders the classic home without the documentation layout for authenticated members' do
      host! portal.custom_domain
      get '/', headers: agent.create_new_auth_token

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('sidebar-drawer-checkbox')
    end
  end
end

