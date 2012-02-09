require 'rubygems'
require 'commander/import'
require 'adobe_crx'

program :name, 'crx'
program :version, '0.0.1'
program :description, 'Command line tools for Adobe CRX.'

global_option "--host HOSTNAME", String, "crx HOSTNAME"
global_option "--port PORT", Float, "crx PORT"
global_option "--username USERNAME", String, "crx USERNAME"
global_option "--password PASSWORD", String, "crx PASSWORD"

def validate_global_options(command, options)
  if !options.host
    options.host = ask 'CRX host:'
  end
  if !options.port
    options.port = ask 'CRX port:'
  else
    options.port = options.port.to_i
  end
  if !options.username
    options.username = ask 'CRX username:'
  end
  if !options.password
    options.password = password('CRX password:')
  end
end

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