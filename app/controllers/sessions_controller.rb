class SessionsController < ApplicationController

  def create
    reset_session
    auth_hash = request.env["omniauth.auth"]

    # OAuth Credentials
    session[:token] = auth_hash["credentials"]["token"]
    session[:instance_url] = auth_hash["credentials"]["instance_url"]

    session[:username] = auth_hash["extra"]["username"]

    redirect_to event_log_files_path
  end

  def destroy
    reset_session
    redirect_to root_path
  end
end