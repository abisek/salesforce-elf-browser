class EventLogFilesController < ApplicationController

  LIST_QUERY = "SELECT Id, EventType, LogDate, LogFileLength FROM EventLogFile"

  before_filter :setup_client

  def index
    redirect_to root_path unless session[:token]

    @username = session[:username]

    # TODO handle exceptions here
    @log_files = @client.query(LIST_QUERY)
  end

  private
  def setup_client
    @client = Databasedotcom::Client.new
    @client.version = "32.0"
    @client.authenticate token: session[:token], instance_url: session[:instance_url]
  end
end