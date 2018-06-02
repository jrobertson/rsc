Gem::Specification.new do |s|
  s.name = 'rsc'
  s.version = '0.4.0'
  s.summary = 'Objectifies remote calls to RSF packages and jobs which ' + 
      'are run through a DRb server'
  s.authors = ['James Robertson']
  s.description = 'formerly known as rcscript-client'
  s.files = Dir['lib/rsc.rb'] 
  s.add_runtime_dependency('rexle', '~> 1.0', '>=1.4.12')
  s.signing_key = '../privatekeys/rsc.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/rsc'
  s.required_ruby_version = '>= 2.1.2'
end
