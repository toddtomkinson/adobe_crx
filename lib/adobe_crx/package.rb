class AdobeCRX::Package
  attr_accessor :name, :filters, :properties
  
  def initialize(name)
    @name = name
    @filters = []
    @properties = {}
  end
  
  def to_json(*a)
    {
      'name' => name,
      'filters' => filters
    }.to_json(*a)
  end
end