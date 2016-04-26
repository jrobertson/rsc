#!/usr/bin/env ruby

# file: rsc.rb

require 'open-uri'
require 'drb'
require 'rexle'


class RSC
  
  class Package
    
    def initialize(drb_obj, parent_url, package)

      @obj = drb_obj

      @url = File.join(parent_url, package + '.rsf')
      doc = Rexle.new open(@url, 'UserAgent' => 'ClientRscript').read
      a = doc.root.xpath 'job/attribute::id'
      
      a.each do |attr|
        method_name = attr.gsub('-','_') 
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

  def initialize(drb_hostname='rse', parent_url)
    
    @parent_url = parent_url
    DRb.start_service
    @obj = DRbObject.new(nil, "druby://#{drb_hostname}:61000")
  end
  
  def run_job(package, job, params={}, *qargs)
    @obj.run_job(package, job, params, qargs)
  end

  private
  
  def method_missing(method_name, *args)
    Package.new @obj, @parent_url, method_name.to_s
  end
  
end