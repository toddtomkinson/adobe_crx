command :import_uber do |c|
  c.syntax = 'crx import_uber [options] <uber package dir> [uber manifest file]'
  c.description = 'Imports an "uber" package from a given directory (and optional manifest file--if not specified the manifest is assumed to be <uber package dir>/manifest.json).'
  c.action do |args, options|
    if !args[0]
      say_error "no uber manifest directory. Use --help for more information"
      exit 1
    end
    if !File.directory? args[0]
      say_error "uber manifest directory (#{args[0]}) does not exist"
      exit 1
    end
    manifest_file = args[1]
    if !manifest_file
      manifest_file = "#{args[0]}/manifest.json"
    end
    if !File.exist? manifest_file
      say_error "uber manifest file (#{manifest_file}) does not exist"
      exit 1
    end
    validate_global_options c, options
    
    client = AdobeCRX::Client.new options.host, options.port, options.username, options.password
    upm = AdobeCRX::UberPackageManager.new client
    upm.import_uber_package manifest_file, args[0]
  end
end