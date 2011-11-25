class Sexp

  def structural_hash
    @structural_hash ||= self.structure.hash
  end

  def accept(visitor, *args)
    visitor.visit(self, *args)
  end

  def all_structural_subhashes
    hashes = []
    deep_each do |n|
      hashes << n.structural_hash
    end
    hashes
  end

  def deep_each(&block)
    children.each do |sexp|
      block[sexp]
      sexp.deep_each(&block)
    end
  end

  def node_type
    first
  end

  def children
    find_all { |s| Sexp === s }
  end

  def is_language_node?
    first.class == Symbol
  end

  def visitable_children
    parent = is_language_node? ? sexp_body : self
    parent.children
  end

end


