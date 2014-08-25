class StackDriverOutput < Fluent::Output

  # Register the plugin as fluent-stackdrive plugin..
  Fluent::Plugin.register_output('stackdriver', self)

  # Initialize is called when the pulgin is first called.
  def initialize
    super
    require 'net/http'
    require 'uri'
    require 'yajl'
  end

  # StackDrive URL ex: https://custom-gateway.stackdriver.com/v1/custom
  config_param :stackdriver_url, :string, :default => 'https://custom-gateway.stackdriver.com/v1/custom'

  # Cloud Type ex: AWS, GCE
  # TODO: Add AWS support for stackdrive output.
  config_param :cloud_type, :string, :default => :gce

  # HTTP method
  config_param :http_method, :string, :default => :post

  # Simple rate limiting
  config_param :rate_limit_msec, :integer, :default => 0

  # StatckDriver API key.
  config_param :api_key, :string, :default => ''

  # Configure is called before starting in order to configure parameters.
  def configure(conf)
    super
    cloud_type = [:gce]
    @cloud_type = if cloud_type.include? @cloud_type.intern
                    @cloud_type.intern
                  else
                    :gce
                  end
  end

  # Start is called when starting.
  def start
    super
  end

  # Shutdown is called when shutting down.
  def shutdown
    super
  end

  # Retrive_gce_id is a helper function used to retrieve gce instance id.
  def retrieve_gce_id()
    url = URI.parse('http://metadata/computeMetadata/v1/instance/id')
    req = Net::HTTP::Get.new(url.path)
    req.add_field("X-Google-Metadata-Request", "True")
    res = Net::HTTP.new(url.host, url.port).start do |http|
      http.request(req)
    end
    return res
  end

  # Format_gce_data is a function used to setup counter name value in a request.
  def format_gce_data(data, record)
    counter_data = Hash.new
    counter_data['collected_at'] = record['@timestamp']
    counter_data['name'] = record['name']
    counter_data['value'] = record['value']
    data['data'] = counter_data
  end


  # Set_header is used to set http request header.
  def set_header(req, tag, time, record)
    req['x-stackdriver-apikey'] = @api_key
    req['user-agent'] = 'Fluent StackDriver Plugin'
    req['Content-Type'] = 'application/json'
  end

  # Set_gce_body is called when cloud_type is gce and used to setup gce request
  # body.
  def set_gce_body(req, tag, time, record)
    data = Hash.new
    data['timestamp'] = record['@timestamp']
    data['proto_version'] = 1
    format_gce_data(data, record)
    req.body = Yajl.dump(data)
  end

  # Set_body is used to set http request body.
  def set_body(req, tag, time, record)
    if @cloud_type = :gce
      set_gce_body(req, tag, time, record)
    end
    req
  end

  # Create_request is called to setup request header and body.
  def create_request(tag, time, record)
    url = @stackdriver_url
    uri = URI.parse(url)
    req = Net::HTTP.const_get(@http_method.to_s.capitalize).new(uri.path)
    set_body(req, tag, time, record)
    set_header(req, tag, time, record)
    return req, uri
  end

  # Send_request is called to send out requests and return if error occurs.
  def send_request(req, uri)
    is_rate_limited = (@rate_limit_msec != 0 and not @last_request_time.nil?)
    if is_rate_limited and ((Time.now.to_f - @last_request_time) * 1000.0 < @rate_limit_msec)
      $log.info('Dropped request due to rate limiting')
      return
    end

    res = nil
    begin
      @last_request_time = Time.now.to_f
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      res = http.request(req)
    rescue IOError, EOFError, SystemCallError
      # server didn't respond
      $log.warn "Net::HTTP.#{req.method.capitalize} raises exception: #{$!.class}, '#{$!.message}'"
    end
    unless res and res.is_a?(Net::HTTPSuccess)
      res_summary = if res
                      "#{res.code} #{res.message} #{res.body}"
                    else
                      "res=nil"
                    end
      $log.warn "failed to #{req.method} #{uri} (#{res_summary})"
    end
  end

  # Handler for setup each record.
  def handle_record(tag, time, record)
    req, uri = create_request(tag, time, record)
    send_request(req, uri)
  end

  # Emit is called when an event reaches Fluentd.
  # NOTE! This method is called by Fluentd's main thread, so it may need to test if record
  # handling is a slow routine work. It may causes Fluentd's performance degression.
  def emit(tag, es, chain)
    chain.next
    es.each {|time,record|
      handle_record(tag, time, record)
    }
  end
end
