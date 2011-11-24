class Sexp

  def structural_hash
    @structural_hash ||= self.structure.hash
  end

  def accept(visitor, file = nil)
    visitor.visit(self, file)
  end

end


