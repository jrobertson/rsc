#!/usr/bin/env ruby

# file: rsc.rb

require 'open-uri'
require 'drb'
require 'rexle'


class RseClient

  def self.call(x)        RSC.new.get(x)        end
  def self.get(x)         RSC.new.get(x)        end
  def self.post(x, val)   RSC.new.post(x, val)  end
  def self.delete(x)      RSC.new.delete(x)     end
  def self.put(x, val)    RSC.new.put(x, val)   end

end

class RSC
  using ColouredText

  class Package
    using ColouredText

    def initialize(drb_obj, package, debug: false)

      @debug = debug

      @obj = drb_obj
      drb_obj.package_methods(package).each do |method_name|

        puts ('creating method ' + method_name).info if @debug

        methodx = "
      def %s(*args, params: {})
        @obj.run_job('%s','%s', params, args)
      end" % [method_name, package, method_name]
        self.instance_eval(methodx)

      end

    end

  end

  def initialize(drb_hostname='rse', port: '61000', odrb2: false, debug: false)

    @debug = debug
    DRb.start_service


    if odrb2 or port == '57844' then
      @port = port =~ /^610[0-9]{2}/ ? '57844' : port

      @obj = DRbObject.new(nil, "druby://#{drb_hostname}:#{@port}")
      parent = @obj
      @obj&.services.each do |name, methods|

        class_name = name.capitalize
        klass = Object.const_set(class_name,Class.new)

        klass.class_eval do
          methods.each do |method_name|
            define_method method_name do |*args|
              parent.call name, method_name, *args
            end
          end
        end

        define_singleton_method name do
          klass.new
        end

      end

      @odrb2 = true

    else

      @port = port
      @obj = DRbObject.new(nil, "druby://#{drb_hostname}:#{@port}")

    end



  end

  # jr: 2022-04-23 the following public methods should be conditionally
  #                created since they are specific to classic RSC and not odrb2

  def delete(s=nil)
    s ? run_uri(s, :delete) :  @obj.delete
  end

  def get(s=nil)
    s ? run_uri(s, :get) :  @obj.get
  end

  def post(s=nil, val=nil)
    s ? run_uri(s, :post, value: val) :  @obj.post
  end

  def put(s=nil, val=nil)
    s ? run_uri(s, :put, value: val) :  @obj.put
  end


  def run_job(package, job, params={}, *qargs, package_path: nil)
    @obj.run_job(package, job, params, qargs, package_path)
  end

  private

  def drb_start(host)
    DRb.start_service
    @obj = DRbObject.new(nil, "druby://#{host}:#{@port}")
  end

  def method_missing(method_name, *args)

    if @debug then
      puts 'method_missing'.info
      puts ('method_name: ' + method_name.inspect).debug
    end

    if not @odrb2 then

      begin
        Package.new @obj, method_name.to_s, debug: @debug
      rescue
        # nil will be returned if there is no package by that name
      end
    end
  end

  def parse_uri(s)

    protocol, _, host, package, raw_job, remaining = s.split('/',6)

    if remaining then

      job = raw_job
      # split on the 1st question mark
      raw_args, raw_params = if remaining =~ /\?/ then
        remaining.split('?',2)
      else
        remaining
      end

    elsif raw_job =~ /\?/
      job, raw_params = raw_job.split('?',2)
    else
      job = raw_job
    end

    if raw_args or raw_params then
      args = raw_args.split('/') if raw_args

      if raw_params then
        params = raw_params.split('&').inject({}) do |r,x|
          k, v = x.split('=')
          v ? r.merge(k[/\w+$/].to_sym => URI.unescape(v)) : r
        end
      end

    end

    [host, package, job, args, params]
  end

  def run_uri(s, type=:get, value: nil)

    host, package, job, args, params = parse_uri(s)
    drb_start host
    @obj.type = type

    if value then
      params ||= {}
      params.merge!(value.is_a?(Hash) ? value : {value: value})
    end

    @obj.run_job(package, job, params, args)

  end
end
