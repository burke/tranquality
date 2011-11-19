module Flog
  module Reporting

    attr_reader :total_score, :totals

    def report(io = $stdout)
      ensure_totals_calculated

      io.puts "%8.1f: %s" % [total_score, "flog total"]
      io.puts "%8.1f: %s" % [average_per_method, "flog/method average"]

      return if options[:score]

      max = options[:all] ? nil : total_score * THRESHOLD
      if options[:group] then
        output_details_grouped io, max
      else
        output_details io, max
      end
    ensure
      self.reset_score_data
    end

    def average_per_method
      return 0 if calls.size == 0
      total_score / calls.size
    end

    # Output the report up to a given max or report everything, if nil.
    def output_details(io, max = nil)
      io.puts

      each_by_score(max) do |class_method, score, call_list|
        return 0 if options[:methods] and class_method =~ /##{NO_METHOD}/

        self.print_score io, class_method, score

        if options[:details] then
          call_list.sort_by { |k,v| -v }.each do |call, count|
            io.puts "  %6.1f:   %s" % [count, call]
          end
          io.puts
        end
      end
    end

    # Output the report, grouped by class/module, up to a given max or
    # report everything, if nil.
    def output_details_grouped(io, max = nil)
      scores  = Hash.new 0
      methods = Hash.new { |h,k| h[k] = [] }

      each_by_score max do |class_method, score, call_list|
        klass = class_method.split(/#|::/).first

        methods[klass] << [class_method, score]
        scores[klass]  += score
      end

      scores.sort_by { |_, n| -n }.each do |klass, total|
        io.puts

        io.puts "%8.1f: %s" % [total, "#{klass} total"]

        methods[klass].each do |name, score|
          self.print_score io, name, score
        end
      end
    end

    # Print out one formatted score.
    def print_score(io, name, score)
      location = @method_locations[name]
      if location then
        io.puts "%8.1f: %-32s %s" % [score, name, location]
      else
        io.puts "%8.1f: %s" % [score, name]
      end
    end

    # Compute the distance formula for a given tally
    def score_method(tally)
      a, b, c = 0, 0, 0
      tally.each do |cat, score|
        case cat
        when :assignment then a += score
        when :branch     then b += score
        else                  c += score
        end
      end
      Math.sqrt(a*a + b*b + c*c)
    end

    # Iterate over the calls sorted (descending) by score.
    def each_by_score(max = nil)
      ensure_totals_calculated
      my_totals = @totals
      current   = 0

      calls.sort_by { |k,v| -my_totals[k] }.each do |class_method, call_list|
        score = my_totals[class_method]

        yield class_method, score, call_list

        current += score
        break if max and current >= max
      end
    end

    def ensure_totals_calculated
      return if @totals
      @total_score = 0
      @totals = Hash.new(0)

      calls.each do |meth, tally|
        next if options[:methods] and meth =~ /##{NO_METHOD}$/
        score = score_method(tally)

        @totals[meth] = score
        @total_score += score
      end
    end

  end
end
