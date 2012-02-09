class AdobeCRX::Node
  attr_accessor :path, :size, :children
  
  def initialize(path)
    @path = path
    @size = 0
    @children = []
    @cached_size = nil
  end
  
  def children_size
    @children.inject(0) {|sum, n| sum + n.size }
  end
  
  def total_size
    if !@cached_size
      @cached_size = @size + (@children.inject(0) {|sum, n| sum + n.total_size })
    end
    @cached_size
  end
end