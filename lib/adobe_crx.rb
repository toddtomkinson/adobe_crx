module AdobeCRX
  class CRXException < RuntimeError
    
  end
end

require 'adobe_crx/version'
require 'adobe_crx/client'
require 'adobe_crx/node'
require 'adobe_crx/package'
require 'adobe_crx/package_filter'
require 'adobe_crx/package_filter_rule'
require 'adobe_crx/package_utils'
require 'adobe_crx/uber_package'
require 'adobe_crx/uber_package_manager'