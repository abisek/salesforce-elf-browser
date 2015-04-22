class EventLogFilesController < ApplicationController

  def index
    redirect_to root_path unless session[:token]

    @username = session[:username]
  end
end