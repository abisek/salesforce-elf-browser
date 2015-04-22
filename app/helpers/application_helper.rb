module ApplicationHelper

  # Return the login path for the OAuth service
  def omniauth_login_path(service)
    "/auth/#{service.to_s}"
  end
end
