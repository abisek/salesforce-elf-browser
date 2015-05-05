module ApplicationHelper

  # Return the login path for the OAuth service
  def omniauth_login_path(service)
    "/auth/#{service.to_s}"
  end


  # Add a flash message
  # Params
  # +type+:: +Symbol+ that represents the flash message type (e.g. warnings, errors, info, etc.)
  # +message+:: +String+ message that is displayed to the user
  def flash_message(type, message)
    flash[type] ||= []
    flash[type] << message
  end
end
