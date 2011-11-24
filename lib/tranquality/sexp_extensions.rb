class Sexp

  def structural_hash
    @structural_hash ||= self.structure.hash
  end

  def accept(visitor, file = nil)
    visitor.visit(self, file)
  end

  def all_structural_subhashes
    hashes = []
    deep_each do |n|
      hashes << n.structural_hash
    end
    hashes
  end

  def deep_each(&block)
    select { |s| s.kind_of?(Sexp) }.each do |sexp|
      block[sexp]
      sexp.deep_each(&block)
    end
  end

end


