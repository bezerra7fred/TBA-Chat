module PortalAuthGuard
  extend ActiveSupport::Concern

  included do
    include DeviseTokenAuth::Concerns::SetUserByToken
    include AccessTokenAuthHelper
  end

  private

  def authenticate_portal_user!
    user = resolve_portal_user

    if user.blank?
      if request.format.html?
        redirect_to portal_login_url, allow_other_host: true and return
      else
        render json: { error: 'You need to sign in before continuing.' }, status: :unauthorized and return
      end
    end

    authorize_portal_user!(user)
  end

  def resolve_portal_user
    if respond_to?(:authenticate_by_access_token?, true) && authenticate_by_access_token?
      authenticate_access_token!
      return @resource if @resource.present?
    end

    set_user_by_token if respond_to?(:set_user_by_token, true)
    return @resource if @resource.present?

    current_user if respond_to?(:current_user)
  end

  def authorize_portal_user!(user)
    return if user.super_admin?

    portal = target_portal
    return if portal.blank?

    return if user.accounts.exists?(id: portal.account_id)

    if request.format.html?
      render plain: 'Forbidden', status: :forbidden and return
    else
      render json: { error: 'You are not authorized to view this portal.' }, status: :forbidden and return
    end
  end

  def target_portal
    @portal || (Portal.find_by(slug: params[:slug]) if params[:slug].present?) || Portal.find_by(custom_domain: request.host)
  end

  def portal_login_url
    frontend_url = ENV.fetch('FRONTEND_URL', nil).presence || "#{request.protocol}#{request.host_with_port}"
    redirect_target = if request.fullpath.to_s.start_with?('/hc')
                        clean_help_center_path(request.fullpath)
                      elsif target_portal.present?
                        locale = target_portal.default_locale.presence || 'en'
                        "/hc/#{target_portal.slug}/#{locale}"
                      else
                        '/hc'
                      end
    "#{frontend_url}/app/login?#{ { redirect_url: redirect_target }.to_query }"
  end

  def clean_help_center_path(path)
    normalized = path.to_s
    return '/hc' unless normalized.start_with?('/hc') && !normalized.start_with?('//') && !normalized.include?('://') && !normalized.include?('\\')

    normalized
  end
end
