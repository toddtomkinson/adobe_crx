class AdobeCRX::PackageFilter
  attr_accessor :root, :rules
  
  def initialize(root, rules = [])
    @root = root
    @rules = rules
  end
  
  def to_json(*a)
    {
      'root' => root,
      'rules' => rules
    }.to_json(*a)
  end
end