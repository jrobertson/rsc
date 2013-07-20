Gem::Specification.new do |s|
  s.name = 'rsc'
  s.version = '0.1.3'
  s.summary = 'rsc'
  s.authors = ['James Robertson']
  s.description = 'formerly known as rcscript-client'
  s.files = Dir['lib/**/*.rb'] 
  s.signing_key = '../privatekeys/rsc.pem'
  s.cert_chain  = ['gem-public_cert.pem']
end
