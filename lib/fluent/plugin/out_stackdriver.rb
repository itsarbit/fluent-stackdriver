class StackDriverOutput < Fluent::Output

  # Register the plugin as fluent-stackdrive plugin..
  Fluent::Plugin.register_output('fluent-stackdriver', self)

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

  # Initialize is called when the pulgin is first called.
  def initialize
    super
    require 'net/http'
    require 'uri'
    require 'yajl'
  end

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

  def format_url(tag, time, record)
    @stackdriver_url
  end

  def format_data(time, name, value)
    fm_data['collect_at'] = time
    fm_data['name'] = name
    fm_data['value'] = value
    return fm_data
  end

  def format_body(tag, time, record)
    fm_record['instance'] = 123
    fm_record['name'] = record['name']
    fm_record['timestamp'] = record['@timestamp']
    fm_record['proto_version'] = 1
    fm_record['data'] = format_data(record['@timestamp'], record['name'], record['value'])
    return fm_record
  end

  def set_header(req, tag, time, record)
    req['x-stackdriver-apikey'] = @api_key
    req['user-agent'] = 'Fluent StackDriver Plugin'
    req['Content-Type'] = 'application/json'
  end

  def set_gce_body(req, tag, time, record)
    req.body = Yajl.dump(format_body(tag, time, record))
  end

  def set_body(req, tag, time, record)
    if @cloud_type = :gce
      set_gce_body(req, tag, time, record)
    end
    req
  end

  def create_request(tag, time, record)
    url = format_url(tag, time, record)
    uri = URI.parse(url)
    req = Net::HTTP.const_get(@http_method.to_s.capitalize).new(uri.path)
    set_body(req, tag, time, record)
    set_header(req, tag, time, record)
    return req, uri
  end

  def send_request(req, uri)
    is_rate_limited = (@rate_limit_msec != 0 and not @last_request_time.nil?)
    if is_rate_limited and ((Time.now.to_f - @last_request_time) * 1000.0 < @rate_limit_msec)
      $log.info('Dropped request due to rate limiting')
      return
    end

    res = nil
    begin
      @last_request_time = Time.now.to_f
      res = Net::HTTP.new(uri.host, uri.port).start {|http| http.request(req) }
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

  # Handler
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
      #$stderr.puts "OK!"
    }
  end
end
