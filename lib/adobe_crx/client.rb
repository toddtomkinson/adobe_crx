require 'rubygems'
require 'rexml/document'
require 'net/http'
require 'net/http/post/multipart'
require 'net/dav'
require 'json'
require 'tmpdir'

# monkey-patch so that we can take advantage of the innards of Net::DAV
module Net 
  class DAV
    def propfind_size(path)
      headers = {'Depth' => 'infinity'}
      body = '<?xml version="1.0" encoding="utf-8"?><DAV:propfind xmlns:DAV="DAV:"><DAV:prop><DAV:getcontentlength/></DAV:prop></DAV:propfind>'
      res = @handler.request(:propfind, path, body, headers)
      total_size = 0
      xml = Nokogiri::XML.parse(res.body)
      namespaces = {'x' => "DAV:"}
      xml./('.//x:response', namespaces).each do |item|
        begin
          total_size = total_size + item.%(".//x:getcontentlength", namespaces).inner_text.to_i
        rescue Exception
          #nothing
        end
      end
      total_size
    end
  end
end

class AdobeCRX::Client
  def initialize(host, port, username, password)
    @host = host
    @port = port
    @username = username
    @password = password
  end
  
  #package management methods
  def list_packages
    xml_data = Net::HTTP.get_response(URI.parse("http://#{@username}:#{@password}@#{@host}:#{@port}/crx/packmgr/service.jsp?cmd=ls")).body
    doc = REXML::Document.new(xml_data)
    
    packages = Array.new
    doc.elements.each("//response/data/packages/package") do |ele|
      package = Hash.new
      packages << package
      ele.elements.each do |child|
        package[child.name] = child.text
      end
    end
    return packages
  end
  
  def upload_package(package_file)
    results = AdobeCRX::PackageUtils.get_package_properties(package_file)
    File.open(package_file) do |package|
      req = Net::HTTP::Post::Multipart.new(
        '/crx/packmgr/service/.json/?cmd=upload', 
        'force' => 'true',
        'package' => UploadIO.new(package, 'application/zip', File.basename(package_file))
      )
      req.basic_auth(@username, @password)
      Net::HTTP.start(@host, @port) do |http|
        response = http.request(req)
        results.merge! JSON.parse(response.body)
      end
    end
    results
  end
  
  def install_package(path)
    req = Net::HTTP::Post.new("/crx/packmgr/service/.json#{path}?cmd=install")
    req.basic_auth(@username, @password)
    result = Hash.new
    Net::HTTP.start(@host, @port) do |http|
      response = http.request(req)
      result.merge! JSON.parse(response.body)
    end
    result
  end
  
  def remove_package(path)
    req = Net::HTTP::Post.new("/crx/packmgr/service/.json#{path}?cmd=delete")
    req.basic_auth(@username, @password)
    result = Hash.new
    Net::HTTP.start(@host, @port) do |http|
      response = http.request(req)
      result.merge! JSON.parse(response.body)
    end
    result
  end

  def export_package(package, dest_file = nil)
    #create the package
    req = Net::HTTP::Post.new('/crx/packmgr/service/.json/etc/packages/my_packages?cmd=create')
    req.basic_auth(@username, @password)
    params = Hash.new
    params['packageName'] = package.name
    params['groupName'] = 'automated-exports'
    req.set_form_data(params)
    create_result = nil
    Net::HTTP.start(@host, @port) do |http|
      response = http.request(req)
      create_result = JSON.parse(response.body)
      if !create_result['success']
        raise AdobeCRX::CRXException, create_result['msg']
      end
    end
    
    #add the filters
    req = Net::HTTP::Post::Multipart.new(
      '/crx/packmgr/update.jsp',
      '_charset_' => 'utf-8',
      'path' => create_result['path'],
      'packageName' => package.name,
      'groupName' => 'automated-exports',
      'filter' => package.filters.to_json
    )
    req.basic_auth(@username, @password)
    Net::HTTP.start(@host, @port) do |http|
      response = http.request(req)
      result = JSON.parse(response.body)
      if !result['success']
        raise AdobeCRX::CRXException, create_result['msg']
      end
    end
    
    #build the package
    req = Net::HTTP::Post.new("/crx/packmgr/service/.json#{create_result['path']}?cmd=build")
    req.basic_auth(@username, @password)
    Net::HTTP.start(@host, @port) do |http|
      http.read_timeout = 1800
      response = http.request(req)
      result = JSON.parse(response.body)
      if !result['success']
        raise AdobeCRX::CRXException, create_result['msg']
      end
    end
    
    #download the package
    file_path = dest_file ? dest_file : "#{Dir.tmpdir}/#{package.name}"
    req = Net::HTTP::Get.new(create_result['path'])
    req.basic_auth(@username, @password)
    Net::HTTP.start(@host, @port) do |http|
      f = File.open(file_path, 'w')
      begin
        http.request(req) do |resp|
          resp.read_body do |segment|
            f.write(segment)
          end
        end
      ensure
        f.close()
      end
    end
    
    #delete the package
    remove_package(create_result['path'])
    
    file_path
  end
  
  def import_package(package_file)
    upload_result = upload_package(package_file)
    if !upload_result['success'] || upload_result['path'] == nil
      raise AdobeCRX::CRXException, "Error uploading package: #{upload_result['msg']}"
    end
    install_result = install_package(upload_result['path'])
    if !install_result['success']
      raise AdobeCRX::CRXException, "Error installing package: #{install_result['msg']}"
    end
    remove_package(upload_result['path'])
    result = "successfully deployed package at #{package_file}:"
    upload_result.each do |key, value|
      result << "\n  #{key}: #{value}"
    end
    result
  end
  
  #content methods
  def get_child_resources(path)
    dav = Net::DAV.new("http://#{@host}:#{@port}", :curl => false)
    dav.credentials(@username, @password)
    
    resources = Array.new
    dav.find(path,:recursive=>false,:suppress_errors=>true) do | item |
      resources << item.uri.path.sub(/\/$/, '')
    end
    resources
  end
  
  def get_node_structure(path, parent = nil, dav = nil)
    if !dav
      dav = Net::DAV.new("http://#{@host}:#{@port}", :curl => false)
      dav.credentials(@username, @password)
    end
    node = AdobeCRX::Node.new path
    if parent
      parent.children << node
    end
    begin
      node.size = dav.propfind_size("#{path}/jcr:content")
    rescue Exception
      #nothing
    end
    dav.find(path,:recursive=>false,:suppress_errors=>true) do | item |
      if path != item.uri.path
        get_node_structure(item.uri.path.sub(/\/$/, ''), node, dav)
      end
    end
    node
  end
  
end