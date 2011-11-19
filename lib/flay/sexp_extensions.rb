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

  # REFACTOR: move to sexp.rb
  def deep_each(&block)
    self.each_sexp do |sexp|
      block[sexp]
      sexp.deep_each(&block)
    end
  end

  # REFACTOR: move to sexp.rb
  def each_sexp
    self.each do |sexp|
      next unless Sexp === sexp

      yield sexp
    end
  end
end

