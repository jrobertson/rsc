#!/usr/bin/env ruby

# file: rsc.rb

require 'open-uri'
require 'drb'
require 'rexle'


class Rse
  
  def self.call(x)        RSC.new.get(x)        end  
  def self.get(x)         RSC.new.get(x)        end
  def self.post(x, val)   RSC.new.post(x, val)  end  
  def self.delete(x)      RSC.new.delete(x)     end
  def self.put(x, val)    RSC.new.put(x, val)   end      
  
end

class RSC
  
  class Package
    
    def initialize(drb_obj, parent_url, package)

      @obj = drb_obj

      @url = File.join(parent_url, package + '.rsf')
      doc = Rexle.new open(@url, 'UserAgent' => 'ClientRscript').read
      a = doc.root.xpath 'job/attribute::id'
      
      a.each do |attr|
        method_name = attr.value.gsub('-','_')         
        method = "def %s(*args); run_job('%s', args) ; end" % \
                                                            ([method_name] * 2)
        self.instance_eval(method)        
        
      end

    end

    private
    
    def run_job(method_name, *args)
      
      args.flatten!(1)
      params = args.pop if args.find {|x| x.is_a? Hash}
      a = ['//job:' + method_name, @url, args].flatten(1)
      params ? @obj.run(a, params) : @obj.run(a)     
    end

  end

  def initialize(drb_hostname='rse', parent_url=nil, port: '61000')
    
    @port = port
    
    if parent_url then
      @parent_url = parent_url
      drb_start(drb_hostname)
    end
    
  end

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
    Package.new @obj, @parent_url, method_name.to_s
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
