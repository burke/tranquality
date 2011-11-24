module Flog
  module Reporting

    attr_reader :total_score, :totals

    def report
      ensure_totals_calculated

      {
        :total_score => total_score,
        :average_per_method => average_per_method,
        :details => report_details
      }
    ensure
      reset_score_data
    end

    def report_details
      h = []
      each_by_score do |class_method, score, call_list|
        h << {
          :score => score,
          :name => class_method,
          :location => @method_locations[class_method],
          :calls => call_list.sort_by { |k, v| -v }
        }
      end
      h
    end

    # Iterate over the calls sorted (descending) by score.
    def each_by_score
      my_totals = @totals
      current   = 0

      calls.sort_by { |k,v| -my_totals[k] }.each do |class_method, call_list|
        score = my_totals[class_method]

        yield class_method, score, call_list

        current += score
      end
    end

    def average_per_method
      return 0 if calls.size == 0
      total_score / calls.size
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

    def ensure_totals_calculated
      return if @totals
      @total_score = 0
      @totals = Hash.new(0)

      calls.each do |meth, tally|
        score = score_method(tally)

        @totals[meth] = score
        @total_score += score
      end
    end

  end
end
