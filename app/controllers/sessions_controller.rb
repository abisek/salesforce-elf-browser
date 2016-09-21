class SessionsController < ApplicationController

  def create
    reset_session
    auth_hash = request.env["omniauth.auth"]

    # OAuth Credentials
    session[:token] = auth_hash["credentials"]["token"]
    session[:instance_url] = auth_hash["credentials"]["instance_url"]

    session[:username] = auth_hash["extra"]["username"]

    setup_databasedotcom_client

    # Check if user has access to Event Log Files. If not logout and notify the user.
    if @client.list_sobjects.include? "LoginHistory"
      redirect_to event_log_files_path
    else
      reset_session
      flash_message(:errors, "We're sorry, but you don't have access to LoginHistory. Please see your administrator.")
      redirect_to root_path
    end
  end

  def destroy
    reset_session
    redirect_to root_path
  end

  def failure
    reset_session
    flash_message(:errors, "OAuth2 login failed. Reason: #{params[:message]}")
    redirect_to root_path
  end
end