command :export do |c|
  c.syntax = 'crx export [options] <root path>'
  c.description = 'Exports a package a simple package for the given root path'
  c.option "--output_file OUTPUT_FILE", String, "package output file"
  c.action do |args, options|
    if !args[0]
      say_error "no root path specified. Use --help for more information"
      exit 1
    end
    validate_global_options c, options
    output_file = options.output_file
    if output_file
      if File.exists? output_file
        overwrite = ask("File #{output_file} exists. Overwrite? (Y/N)")
        if overwrite == 'Y'
          File.delete output_file
        else
          exit 1
        end
      end
    end
    
    package = AdobeCRX::Package.new "export-#{Time.now.strftime('%Y%m%d%H%M%S')}-#{args[0]}".gsub('/', '-').gsub(' ', '_').gsub("%20", '_')
    package.filters << AdobeCRX::PackageFilter.new(args[0])
    
    client = AdobeCRX::Client.new options.host, options.port, options.username, options.password
    client.export_package package, output_file
  end
end