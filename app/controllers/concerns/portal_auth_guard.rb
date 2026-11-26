module PortalAuthGuard
  extend ActiveSupport::Concern

  included do
    include RequestExceptionHandler
    include DeviseTokenAuth::Concerns::SetUserByToken
    include AccessTokenAuthHelper
  end

  private

  def resource_name
    :user
  end

  def authenticate_portal_user!
    user = resolve_portal_user
    return if performed?

    if user.blank? || !user.is_a?(User)
      handle_unauthenticated_portal_user
    else
      authorize_portal_user!(user)
    end
  end

  def handle_unauthenticated_portal_user
    if request.format.html?
      redirect_to portal_login_url, allow_other_host: true
    else
      render json: { error: 'You need to sign in before continuing.' }, status: :unauthorized
    end
  end

  def resolve_portal_user
    if access_token_authentication?
      resolve_access_token_user
    else
      resolve_token_user
    end
  end

  def access_token_authentication?
    respond_to?(:authenticate_by_access_token?, true) && authenticate_by_access_token?
  end

  def resolve_access_token_user
    authenticate_access_token!
    return nil if performed?

    return @resource if @resource.is_a?(User)

    Current.user = nil
    render_portal_response('Forbidden', 'Access to this portal is not authorized for bots', :unauthorized)
    nil
  end

  def resolve_token_user
    set_user_by_token if respond_to?(:set_user_by_token, true)
    return @resource if @resource.is_a?(User)

    current_user if respond_to?(:current_user) && current_user.is_a?(User)
  end

  def authorize_portal_user!(user)
    return if user.is_a?(SuperAdmin)

    portal = target_portal
    return render_portal_response('Not Found', 'Portal not found', :not_found) if portal.blank?
    return if user.is_a?(User) && user.account_users.exists?(account_id: portal.account_id)

    render_portal_response('Forbidden', 'You are not authorized to view this portal.', :forbidden)
  end

  def render_portal_response(plain_msg, json_msg, status)
    if request.format.html?
      html_status = status == :unauthorized ? :forbidden : status
      render plain: plain_msg, status: html_status
    else
      render json: { error: json_msg }, status: status
    end
  end

  def target_portal
    return @portal if @portal.present?

    @portal = if params[:slug].present?
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
    return clean_help_center_path(request.fullpath) if request.fullpath.to_s.start_with?('/hc')

    if target_portal.present?
      locale = target_portal.default_locale.presence || 'en'
      return "/hc/#{target_portal.slug}/#{locale}"
    end

    '/hc'
  end

  def clean_help_center_path(path)
    normalized = path.to_s
    valid = normalized.start_with?('/hc') &&
            !normalized.start_with?('//') &&
            normalized.exclude?('://') &&
            normalized.exclude?('\\')
    valid ? normalized : '/hc'
  end
end
