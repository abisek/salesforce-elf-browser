class PagesController < ApplicationController

  def index
    redirect_to event_log_files_path if logged_in?
  end

end
