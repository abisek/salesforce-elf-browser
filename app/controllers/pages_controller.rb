class PagesController < ApplicationController

  def index
    redirect_to event_log_files_path if session[:token]
  end

end
