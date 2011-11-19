module Flog
  module ProcessMethodHelpers

    def add_to_score(name, score = OTHER_SCORES[name])
      @calls[signature][name] += score * @penalization_factor
    end

    # Adds name to the class stack for the duration of the block
    def in_class(name)
      name = class_name_from_sexp(name) if name.kind_of?(Sexp)
      @class_stack.unshift name
      yield
      @class_stack.shift
    end

    def class_name_from_sexp(sexp)
      case sexp.first
      when :colon2 then
        sexp = sexp.flatten
        sexp.delete :const
        sexp.delete :colon2
        sexp.join("::")
      when :colon3 then
        sexp.last.to_s
      else
        raise "unknown type #{sexp.inspect}"
      end
    end

    # Adds name to the method stack, for the duration of the block
    def in_method(name, file, line)
      method_name = name.kind_of?(Regexp) ? name.inspect : name.to_s
      @method_stack.unshift method_name
      @method_locations[signature] = "#{file}:#{line}"
      yield
      @method_stack.shift
    end

    def process_until_empty exp
      process exp.shift until exp.empty?
    end

    # Increase the complexity multiplier for the duration of the block
    def penalize_by(factor)
      @penalization_factor += factor
      yield
      @penalization_factor -= factor
    end

    def method_name
      m = @method_stack.first || NO_METHOD
      m = "##{m}" unless m =~ /::/
      m
    end

    def klass_name
      if @class_stack.any?
        @class_stack.reverse.join("::")
      else
        NO_CLASS
      end
    end

    def signature
      "#{klass_name}#{method_name}"
    end

  end
end
