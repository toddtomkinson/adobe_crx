require File.join(File.dirname(__FILE__), "lib", "adobe_crx", "version")

Gem::Specification.new do |spec|
  files = []
  paths = %w{lib}
  paths.each do |path|
    if File.file?(path)
      files << path
    else
      files += Dir["#{path}/**/*"]
    end
  end

  rev = Time.now.strftime("%Y%m%d%H%M%S")
  spec.name = "adobe_crx"
  spec.version = ADOBE_CRX_VERSION
  spec.summary = "ruby client used to manage day/adobe crx instances"
  spec.description = "Ruby client used to manage day/adobe crx instances. Also includes utilities for performing common maintenance tasks."
  spec.license = "Apache License (2.0)"

  spec.add_dependency "json"
  spec.add_dependency "rubyzip"
  spec.add_dependency "multipart-post"
  spec.add_dependency "net_dav"
  spec.add_dependency "commander"

  spec.files = files
  spec.require_paths << "lib"
  spec.bindir = "bin"
  spec.executables << "crx"

  spec.authors = ["Todd Tomkinson"]
  spec.email = ["todd.g.tomkinson@gmail.com"]
  spec.homepage = "https://github.com/toddtomkinson/adobe_crx"
end