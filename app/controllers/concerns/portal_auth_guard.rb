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
      return nil if performed?

      unless @resource.is_a?(User)
        Current.user = nil
        if request.format.html?
          render plain: 'Forbidden', status: :forbidden
        else
          render json: { error: 'Access to this portal is not authorized for bots' }, status: :unauthorized
        end
        return nil
      end

      return @resource
    end

    set_user_by_token if respond_to?(:set_user_by_token, true)
    return @resource if @resource.is_a?(User)

    user = current_user if respond_to?(:current_user)
    user if user.is_a?(User)
  end

  def authorize_portal_user!(user)
    unless user.is_a?(User)
      if request.format.html?
        render plain: 'Forbidden', status: :forbidden and return
      else
        render json: { error: 'You are not authorized to view this portal.' }, status: :forbidden and return
      end
    end

    return if user.super_admin?

    portal = target_portal
    if portal.blank?
      if request.format.html?
        render plain: 'Not Found', status: :not_found and return
      else
        render json: { error: 'Portal not found' }, status: :not_found and return
      end
    end

    return if user.account_users.exists?(account_id: portal.account_id)

    if request.format.html?
      render plain: 'Forbidden', status: :forbidden and return
    else
      render json: { error: 'You are not authorized to view this portal.' }, status: :forbidden and return
    end
  end

  def target_portal
    @portal || (Portal.where(slug: params[:slug], archived: false).first if params[:slug].present?) || Portal.where(custom_domain: request.host, archived: false).first
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
