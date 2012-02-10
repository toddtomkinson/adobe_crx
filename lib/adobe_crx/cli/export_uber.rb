command :export_uber do |c|
  c.syntax = 'crx export_uber [options] <uber manifest location>'
  c.description = 'Exports an "uber" package based on a manifest file (see the generate_uber_manifest command).'
  c.option "--output_dir OUTPUT_DIR", String, "uber package output directory"
  c.action do |args, options|
    if !args[0]
      say_error "no uber manifest specified. Use --help for more information"
      exit 1
    end
    if !File.exist? args[0]
      say_error "uber manifest file (#{args[0]}) does not exist"
      exit 1
    end
    validate_global_options c, options
    output_dir = options.output_dir
    if output_dir
      if !File.writable? output_dir
        say_error "unable to write to output directory #{output_dir}"
        exit 1
      end
    end
    
    client = AdobeCRX::Client.new options.host, options.port, options.username, options.password
    upm = AdobeCRX::UberPackageManager.new client
    json = upm.export_uber_package args[0], output_dir
  end
end