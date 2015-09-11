# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'scon/version'

Gem::Specification.new do |spec|
  spec.name          = "scon"
  spec.version       = SCON::VERSION
  spec.authors       = ["JacisNonsense"]
  spec.email         = ["jaci.brunning@gmail.com"]

  spec.summary       = %q{Simple and Compressed Object Notation}
  spec.description   = %q{Simple and Compressed Object Notation (SCON) serializes arrays
    and objects into a binary format, all the while using as little space as possible by
    reusing duplicate keys with a binary reference and clever type definitions.}
  spec.homepage      = "http://www.github.com/JacisNonsense/scon"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.bindir        = "bin"
  spec.files = Dir.glob("lib/**/*") + ['Rakefile', 'scon.gemspec', 'Gemfile', 'Rakefile']
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
