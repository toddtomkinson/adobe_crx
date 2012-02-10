command :import do |c|
  c.syntax = 'crx import [options] <package file>'
  c.description = 'Imports a package to the target crx instance'
  c.action do |args, options|
    if !args[0]
      say_error "no package file specified. Use --help for more information"
      exit 1
    end
    if !File.exist? args[0]
      say_error "package file (#{args[0]}) does not exist"
      exit 1
    end
    validate_global_options c, options
    
    client = AdobeCRX::Client.new options.host, options.port, options.username, options.password
    client.import_package args[0]
  end
end