class Flay
  module Reporter

    def report
      {
        :total_score => total,
        :details => details
      }
    end

    def details
      masses.sort_by { |h,m| [-m, hashes[h].first.file] }.map do |hash, mass|
        nodes = hashes[hash]

        if identical[hash]
          similarity = :identical
          bonus = nodes.size
        else
          similarity = :similar
          bonus = nil
        end

        {
          :similarity => similarity,
          :bonus => bonus,
          :mass => mass,
          :locations => nodes.map { |x| [x.file, x.line] }
        }
      end
    end

  end
end
