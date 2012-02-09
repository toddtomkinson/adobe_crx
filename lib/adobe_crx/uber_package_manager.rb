require 'json'

class AdobeCRX::UberPackageManager
  def initialize(client)
    @client = client
  end
  
  def generate_uber_package_definition(name, root_path, options = {})
    opts = {
      :target_package_size => 1024*1024*1024*2 #1GB
    }.merge(options)
    
    root_node = @client.get_node_structure root_path
    
    uber = AdobeCRX::UberPackage.new name
    root_package = AdobeCRX::Package.new "#{name}-root"
    uber.packages << root_package
    root_filter = AdobeCRX::PackageFilter.new root_path
    root_package.filters << root_filter
    root_package.properties[:size] = root_node.size
    process_node_for_uber(name, root_node, uber.packages, root_package, opts)
    
    JSON.pretty_generate(JSON.parse(uber.to_json))
  end
  
  def export_uber_package(uber_package_definition, dest_dir = nil)
    uber = AdobeCRX::UberPackage.from_json uber_package_definition
    
    uber_dir = dest_dir ? dest_dir : "#{Dir.tmpdir}/uber_packages/#{uber.name}"
    FileUtils.mkpath uber_dir
    
    #export the packages to the uber_dir 
    uber.packages.each do |package|
      puts "exporting #{package.name}..."
      @client.export_package(package, "#{uber_dir}/#{package.name}.zip")
    end
  end
  
  def import_uber_package(uber_package_dir, uber_package_definition = nil)
    
  end
  
  private
  
  def process_node_for_uber(name, node, packages, current_package, options)
    puts "#{node.path}: #{current_package.properties[:size]}, #{node.size}, #{node.children_size}, #{node.total_size}"
    if node.total_size > 0
      branch_to_new_package = (
        ((node.size + current_package.properties[:size]) > options[:target_package_size]) || 
        ((node.children_size + current_package.properties[:size]) > options[:target_package_size])
      )
      
      if branch_to_new_package
        current_package.filters[0].rules << AdobeCRX::PackageFilterRule.new('exclude', node.path)
        current_package.filters[0].rules << AdobeCRX::PackageFilterRule.new('exclude', "#{node.path}/.*")
        new_package = AdobeCRX::Package.new "#{name}-#{node.path}".gsub('/', '-').gsub(' ', '_').gsub("%20", '_')
        packages << new_package
        new_filter = AdobeCRX::PackageFilter.new node.path
        new_package.filters << new_filter
        new_package.properties[:size] = node.size
        node.children.each do |child|
          process_node_for_uber(name, child, packages, new_package, options)
        end
      else
        current_package.properties[:size] = current_package.properties[:size] + node.size
        node.children.each do |child|
          process_node_for_uber(name, child, packages, current_package, options)
        end
      end
    end
  end
end