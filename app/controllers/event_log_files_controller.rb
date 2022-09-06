class EventLogFilesController < ApplicationController
  include ActionController::Live

  ALL_EVENTS_TYPE = "All"

  before_action :setup_databasedotcom_client

  def index
    redirect_to root_path unless logged_in?

    @username = session[:username]

    load_and_cache_elf_metadata unless metadata_cached?
    @event_types = session["event_types"]
    @has_one_hr_elf = session["has_one_hr_elf"]

    if params[:daterange].nil? && params[:eventtype].nil?
      default_params_redirect
      return
    elsif params[:daterange].nil? || params[:daterange].empty?
      flash_message(:warnings, "The 'daterange' query parameter is invalid. Displaying default date range.")
      default_params_redirect
      return
    elsif params[:eventtype].nil? || params[:eventtype].empty?
      flash_message(:warnings, "The 'eventtype' query parameter is invalid. Displaying all event types.")
      default_params_redirect
      return
    end

    @event_type = @event_types.find { |event_type| event_type.downcase == params[:eventtype].downcase }
    
    if params[:interval].nil?
      @interval = "all"
    else
      @interval = params[:interval]
    end

    if @event_type.nil?
      flash_message(:warnings, "The 'eventtype' query parameter with value '#{params[:eventtype]}' is invalid. Displaying all event types.")
      default_params_redirect
      return
    end

    begin
      @start_date, @end_date = date_range_parser(params[:daterange])
    rescue ArgumentError => e
      flash_message(:warnings, "The 'daterange' query parameter with value '#{params[:daterange]}' is invalid. Displaying default date range.")
      default_params_redirect
      return
    end

    begin
      select_clause = if @has_one_hr_elf
                        'SELECT Id, EventType, LogDate, LogFileLength, Sequence, Interval'
                      else
                        'SELECT Id, EventType, LogDate, LogFileLength'
                      end

      order_by_clause = if @has_one_hr_elf
                          'ORDER BY LogDate DESC, EventType, Sequence, Interval'
                        else
                          'ORDER BY LogDate DESC, EventType'
                        end      

      where_clause_addition = if @has_one_hr_elf
                                case @interval
                                when "daily"
                                  "AND Interval = 'Daily' "
                                when "hourly"
                                  "AND Interval = 'Hourly' "
                                else
                                  "AND (Interval = 'Hourly' OR Interval = 'Daily') "
                                end
                              else
                                ""
                              end
      if @event_type == ALL_EVENTS_TYPE
        @log_files = @client.query("#{select_clause} FROM EventLogFile WHERE LogDate >= #{date_to_time(@start_date)} AND LogDate < #{date_to_time(@end_date + 1)} #{where_clause_addition}#{order_by_clause}")
      else
        @log_files = @client.query("#{select_clause} FROM EventLogFile WHERE LogDate >= #{date_to_time(@start_date)} AND LogDate < #{date_to_time(@end_date + 1)} AND EventType = '#{@event_type}' #{where_clause_addition}#{order_by_clause}")
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

  def show
    begin
      @elf_info = @client.find("EventLogFile", params[:id])
    rescue Databasedotcom::SalesForceError => e
      if e.message == "Session expired or invalid"
        redirect_to logout_path
        return
      elsif e.message.start_with?("Provided external ID field does not exist or is not accessible")
        @error_message = "Event log file with ID #{params[:id]} does not exist or is not accessible"
        render 'event_log_files/error', status: :not_found
        return
      else
        raise e
      end
    end

    if (params[:script])
      @log_files = [@elf_info]
      # @shell_escaped_token = Shellwords.escape(@token)
      response.headers["Content-Disposition"] = "attachment; filename=#{@elf_info.LogDate.to_date}_#{@elf_info.EventType}.sh"
      render 'event_log_files/download_script.sh.erb', layout: false, content_type: 'text/plain'
    else
      if @elf_info.LogFileLength > Rails.configuration.x.elf.max_download_file_size_in_bytes
        render 'event_log_files/large_file', status: :bad_request
        return
      else
        # Stream the file download
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = "attachment; filename=\"#{@elf_info.LogDate.to_date}_#{@elf_info.EventType}.csv\""

        begin
          @client.http_streaming_get(@elf_info.LogFile, response.stream)
        rescue Databasedotcom::SalesForceError => e
          response.headers.delete('Content-Type')
          response.headers.delete('Content-Disposition')
          @error_message = e.message
          render 'event_log_files/error', status: :bad_request
        else
          response.stream.close
        end
        return
      end
    end
  end

  private
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

  # helper method to dynamically generate the valid event log file event types
  def get_event_types(fields)
    pick_list_values = []
    for field in fields
      if field["name"] == "EventType"
        field["picklistValues"].each {|v| pick_list_values.push(v["value"])}
        break
      end
    end
    return pick_list_values.dup.unshift(ALL_EVENTS_TYPE)
  end

  # helper method to identify whether an org has 1-hr ELF
  def one_hour_elf?(fields)
    fields.each do |field|
      if field["name"] == "Sequence"
        return true
      end
    end
    return false
  end

  def metadata_cached?
    session[:event_types] && session[:has_one_hr_elf]
  end

  def load_and_cache_elf_metadata
    fields = @client.describe_sobject("EventLogFile")["fields"]
    session[:event_types] = get_event_types(fields)
    session[:has_one_hr_elf] = one_hour_elf?(fields)
  end
end