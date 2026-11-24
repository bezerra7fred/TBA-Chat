module PortalAuthGuard
  extend ActiveSupport::Concern

  included do
    include RequestExceptionHandler
    include DeviseTokenAuth::Concerns::SetUserByToken
    include AccessTokenAuthHelper
  end

  private

  def authenticate_portal_user!
    user = resolve_portal_user
    return if performed?

    if user.blank? || !user.is_a?(User)
      handle_unauthenticated_portal_user
      return
    end

    authorize_portal_user!(user)
  end

  def handle_unauthenticated_portal_user
    if request.format.html?
      redirect_to portal_login_url, allow_other_host: true
    else
      render json: { error: 'You need to sign in before continuing.' }, status: :unauthorized
    end
  end

  def resolve_portal_user
    if respond_to?(:authenticate_by_access_token?, true) && authenticate_by_access_token?
      return resolve_access_token_user
    end

    resolve_session_or_devise_user
  end

  def resolve_access_token_user
    authenticate_access_token!
    return nil if performed?

    unless @resource.is_a?(User)
      Current.user = nil
      render_bot_unauthorized
      return nil
    end

    @resource
  end

  def render_bot_unauthorized
    if request.format.html?
      render plain: 'Forbidden', status: :forbidden
    else
      render json: { error: 'Access to this portal is not authorized for bots' }, status: :unauthorized
    end
  end

  def resolve_session_or_devise_user
    set_user_by_token if respond_to?(:set_user_by_token, true)
    return @resource if @resource.is_a?(User)

    user = current_user if respond_to?(:current_user)
    user if user.is_a?(User)
  end

  def authorize_portal_user!(user)
    unless user.is_a?(User)
      render_portal_forbidden
      return
    end

    return if user.super_admin?

    portal = target_portal
    if portal.blank?
      render_portal_not_found
      return
    end

    return if user_belongs_to_portal_account?(user, portal)

    render_portal_forbidden
  end

  def user_belongs_to_portal_account?(user, portal)
    user.account_users.exists?(account_id: portal.account_id)
  end

  def render_portal_forbidden
    if request.format.html?
      render plain: 'Forbidden', status: :forbidden
    else
      render json: { error: 'You are not authorized to view this portal.' }, status: :forbidden
    end
  end

  def render_portal_not_found
    if request.format.html?
      render plain: 'Not Found', status: :not_found
    else
      render json: { error: 'Portal not found' }, status: :not_found
    end
  end

  def target_portal
    return @portal if @portal.present?

    if params[:slug].present?
      Portal.find_by(slug: params[:slug], archived: false)
    else
      Portal.find_by(custom_domain: request.host, archived: false)
    end
  end

  def portal_login_url
    frontend_url = ENV.fetch('FRONTEND_URL', nil).presence || "#{request.protocol}#{request.host_with_port}"
    query = { redirect_url: portal_redirect_target }.to_query
    "#{frontend_url}/app/login?#{query}"
  end

  def portal_redirect_target
    if request.fullpath.to_s.start_with?('/hc')
      clean_help_center_path(request.fullpath)
    elsif target_portal.present?
      locale = target_portal.default_locale.presence || 'en'
      "/hc/#{target_portal.slug}/#{locale}"
    else
      '/hc'
    end
  end

  def clean_help_center_path(path)
    normalized = path.to_s
    return '/hc' unless valid_help_center_path?(normalized)

    normalized
  end

  def valid_help_center_path?(path)
    path.start_with?('/hc') &&
      !path.start_with?('//') &&
      !path.include?('://') &&
      !path.include?('\\')
  end
end
