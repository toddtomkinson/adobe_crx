require 'rubygems'
require 'commander/import'
require 'adobe_crx'

program :name, 'crx'
program :version, ADOBE_CRX_VERSION
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

Dir.foreach(File.dirname(__FILE__) + '/cli') do |filename|
  to_require = File.basename(filename, '.rb')
  if !to_require.match(/^\./)
    require "adobe_crx/cli/#{to_require}"
  end
end