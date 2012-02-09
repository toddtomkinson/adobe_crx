class AdobeCRX::UberPackage
  attr_accessor :name, :packages
  
  def initialize(name)
    @name = name
    @packages = []
  end
  
  def to_json(*a)
    {
      'name' => name,
      'packages' => packages
    }.to_json(*a)
  end
  
  def self.from_json(json)
    data = JSON.parse(json)
    uber = AdobeCRX::UberPackage.new data['name']
    data['packages'].each do |p|
      package = AdobeCRX::Package.new p['name']
      uber.packages << package
      p['filters'].each do |f|
        filter = AdobeCRX::PackageFilter.new f['root']
        package.filters << filter
        f['rules'].each do |r|
          filter.rules << AdobeCRX::PackageFilterRule.new(r['modifier'], r['pattern'])
        end
      end
    end
    uber
  end
end