class AdobeCRX::PackageFilterRule
  attr_accessor :modifier, :pattern
  
  def initialize(modifier, pattern)
    @modifier = modifier
    @pattern = pattern
  end
  
  def to_json(*a)
    {
      'modifier' => modifier,
      'pattern' => pattern
    }.to_json(*a)
  end
end