command :generate_uber_manifest do |c|
  c.syntax = 'crx generate_uber_manifest [options] <root path>'
  c.description = 'Generates an uber package manifest.'
  c.option "--output_file OUTPUT_FILE", String, "uber manifest output file location"
  c.option "--export_name EXPORT_NAME", String, "export name"
  c.option "--root_package_depth ROOT_PACKAGE_DEPTH", String, "specify the node depth of the root package.  defaults to '1'"
  c.option "--target_package_size TARGET_PACKAGE_SIZE", String, "specify the desired size of 'leaf' packages.  defaults to '0', which means to not check content size (results in faster manifest creation)"
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
    export_name = options.export_name
    export_name = 'export' if !export_name
    
    uber_options = {}
    if options.root_package_depth
      uber_options[:root_package_depth] = options.root_package_depth.to_i
    end
    if options.target_package_size
      uber_options[:target_package_size] = options.target_package_size.to_i
    end
    
    client = AdobeCRX::Client.new options.host, options.port, options.username, options.password
    upm = AdobeCRX::UberPackageManager.new client
    json = upm.generate_uber_package_definition export_name, args[0], uber_options
    if output_file
      File.open output_file, 'w' do |f|
        f.write(json)
      end
    else
      puts json
    end
  end
end