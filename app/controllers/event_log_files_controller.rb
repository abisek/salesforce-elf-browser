class EventLogFilesController < ApplicationController

  ALL_EVENTS_TYPE = "All"
  EVENT_TYPES = %w(API ApexCallout ApexExecution ApexSoap ApexTrigger AsyncReportRun BulkApi ChangeSetOperation\
                   ContentDistribution ContentDocumentLink ContentTransfer Dashboard DocumentAttachmentDownloads\
                   Login LoginAs Logout MetadataApiOperation MultiBlockReport PackageInstall Report ReportExport\
                   RestApi Sandbox Sites TimeBasedWorkflow UITracking URI VisualforceRequest)

  API_VERSION = "32.0"

  before_filter :setup_client

  def index
    redirect_to root_path unless logged_in?

    @username = session[:username]
    @event_types = EVENT_TYPES.dup.unshift(ALL_EVENTS_TYPE)

    if params[:daterange].nil? || params[:eventtype].nil?
      default_params_redirect
      return
    end

    @event_type = @event_types.find { |event_type| event_type.downcase == params[:eventtype].downcase }

    if @event_type.nil?
      default_params_redirect
      # TODO Display errors
      return
    end

    begin
      @start_date, @end_date = date_range_parser(params[:daterange])
    rescue ArgumentError => e
      default_params_redirect
      # TODO Display errors
      return
    end

    begin
      if @event_type == ALL_EVENTS_TYPE
        @log_files = @client.query("SELECT Id, EventType, LogDate, LogFileLength FROM EventLogFile WHERE LogDate >= #{date_to_time(@start_date)} AND LogDate <= #{date_to_time(@end_date)} ORDER BY LogDate DESC")
      else
        @log_files = @client.query("SELECT Id, EventType, LogDate, LogFileLength FROM EventLogFile WHERE LogDate >= #{date_to_time(@start_date)} AND LogDate <= #{date_to_time(@end_date)} AND EventType = '#{@event_type}' ORDER BY LogDate DESC" )
      end
    rescue Databasedotcom::SalesForceError => e
      # Session has expired. Force user logout.
      if e.message == "Session expired or invalid"
        redirect_to logout_path
      else
        raise e
      end
    end
  end

  private
  def setup_client
    @client = Databasedotcom::Client.new
    @client.version = API_VERSION
    @client.authenticate token: session[:token], instance_url: session[:instance_url]
  end

  # return [start_date, end_date] from a query string (e.g. "2015-01-01 to 2015-01-02"). Returned dates are of Date class.
  def date_range_parser(query_string)
    begin
      start_date, end_date = query_string.split("to").map { |date_str| date_str.strip! }. map { |date_str| Date.parse(date_str) }
    rescue
      raise ArgumentError, "unable to parse date"
    end
    raise ArgumentError, "end date must be on or after begin date" if end_date < start_date
    [start_date, end_date]
  end

  # Returns the default date for filter.
  def default_date
    # We set yesterday as default date since that's the latest log file that is generated.
    Date.today - 1
  end

  def default_params_redirect
    redirect_to event_log_files_path(daterange: "#{default_date.to_s} to #{default_date.to_s}", eventtype: ALL_EVENTS_TYPE)
  end

  # Helper method to transform date (e.g. 2015-01-01) to time in ISO8601 format (e.g. 2015-01-01T00:00:00.000Z)
  def date_to_time(date)
    date.to_time(:utc).to_formatted_s(:iso8601)
  end
end