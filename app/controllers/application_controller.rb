class ApplicationController < ActionController::Base
  include ApplicationHelper

  SALESFORCE_API_VERSION = "46.0"

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :logged_in?, :username

  def logged_in?
    !!session[:token]
  end

  def username
    session[:username]
  end

  def setup_databasedotcom_client
    @client = Databasedotcom::Client.new
    @client.version = SALESFORCE_API_VERSION
    @instance_url = session[:instance_url]
    @token = session[:token]
    @client.authenticate token: @token, instance_url: @instance_url
  end

end
