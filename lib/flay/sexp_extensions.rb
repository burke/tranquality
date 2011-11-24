class Sexp

  def structural_hash
    @structural_hash ||= self.structure.hash
  end

  def all_structural_subhashes
    hashes = []
    self.deep_each do |node|
      hashes << node.structural_hash
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

