require 'zip/zip'
require 'rexml/document'

class AdobeCRX::PackageUtils
  def self.get_package_properties(package_file)
    Zip::ZipFile.open(package_file.respond_to?(:path) ? package_file.path : package_file, Zip::ZipFile::CREATE) do |zipfile|
      doc = REXML::Document.new(zipfile.read("META-INF/vault/properties.xml"))
      properties = Hash.new
      doc.elements.each("//properties/entry") do |ele|
        properties[ele.attributes['key']] = ele.text
      end
      return properties
    end
  end
end