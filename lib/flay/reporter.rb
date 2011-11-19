class Flay
  module Reporter
    def n_way_diff *data
      data.each_with_index do |s, i|
        c = (?A.ord + i).chr
        s.group = c
      end

      max = data.map { |s| s.scan(/^.*/).size }.max

      data.map! { |s| # FIX: this is tarded, but I'm out of brain
        c = s.group
        s = s.scan(/^.*/)
        s.push(*([""] * (max - s.size))) # pad
        s.each do |o|
          o.group = c
        end
        s
      }

      groups = data[0].zip(*data[1..-1])
      groups.map! { |lines|
        collapsed = lines.uniq
        if collapsed.size == 1 then
          "   #{lines.first}"
        else
          # TODO: make r2r have a canonical mode (doesn't make 1-liners)
          lines.reject { |l| l.empty? }.map { |l| "#{l.group}: #{l}" }
        end
      }
      groups.flatten.join("\n")
    end

    def summary
      score = Hash.new 0

      masses.each do |hash, mass|
        sexps = hashes[hash]
        mass_per_file = mass.to_f / sexps.size
        sexps.each do |sexp|
          score[sexp.file] += mass_per_file
        end
      end

      score
    end

    def report prune = nil
      puts "Total score (lower is better) = #{self.total}"
      puts

      if option[:summary] then

        self.summary.sort_by { |_,v| -v }.each do |file, score|
          puts "%8.2f: %s" % [score, file]
        end

        return
      end

      count = 0
      masses.sort_by { |h,m| [-m, hashes[h].first.file] }.each do |hash, mass|
        nodes = hashes[hash]
        next unless nodes.first.first == prune if prune
        puts

        same = identical[hash]
        node = nodes.first
        n = nodes.size
        match, bonus = if same then
                         ["IDENTICAL", "*#{n}"]
                       else
                         ["Similar",   ""]
                       end

        count += 1
        puts "%d) %s code found in %p (mass%s = %d)" %
          [count, match, node.first, bonus, mass]

        nodes.each_with_index do |x, i|
          if option[:diff] then
            c = (?A.ord + i).chr
            puts "  #{c}: #{x.file}:#{x.line}"
          else
            puts "  #{x.file}:#{x.line}"
          end
        end

        if option[:diff] then
          puts
          r2r = Ruby2Ruby.new
          puts n_way_diff(*nodes.map { |s| r2r.process(s.deep_clone) })
        end
      end
    end

  end
end
