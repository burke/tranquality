module Flog
  module ProcessMethods

    def process_alias(exp)
      process exp.shift
      process exp.shift
      add_to_score :alias
      s()
    end

    def process_and(exp)
      add_to_score :branch
      penalize_by 0.1 do
        process exp.shift # lhs
        process exp.shift # rhs
      end
      s()
    end
    alias :process_or :process_and

    def process_attrasgn(exp)
      add_to_score :assignment
      process exp.shift # lhs
      exp.shift # name
      process exp.shift # rhs
      s()
    end

    def process_block(exp)
      penalize_by 0.1 do
        process_until_empty exp
      end
      s()
    end

    def process_block_pass(exp)
      arg = exp.shift

      add_to_score :block_pass

      case arg.first
      when :lvar, :dvar, :ivar, :cvar, :self, :const, :colon2, :nil then
        # do nothing
      when :lit, :call then
        add_to_score :to_proc_normal
      when :lasgn then # blah(&l = proc { ... })
        add_to_score :to_proc_lasgn
      when :iter, :dsym, :dstr, *BRANCHING then
        add_to_score :to_proc_icky!
      else
        raise({:block_pass_even_ickier! => arg}.inspect)
      end

      process arg

      s()
    end

    def process_call(exp)
      penalize_by 0.2 do
        process exp.shift # recv
      end
      name = exp.shift
      penalize_by 0.2 do
        process exp.shift # args
      end

      add_to_score name, SCORES[name]

      s()
    end

    def process_case(exp)
      add_to_score :branch
      process exp.shift # recv
      penalize_by 0.1 do
        process_until_empty exp
      end
      s()
    end

    def process_class(exp)
      in_class exp.shift do
        penalize_by 1.0 do
          process exp.shift # superclass expression
        end
        process_until_empty exp
      end
      s()
    end

    def process_dasgn_curr(exp) # FIX: remove
      add_to_score :assignment
      exp.shift # name
      process exp.shift # assigment, if any
      s()
    end
    alias :process_iasgn :process_dasgn_curr
    alias :process_lasgn :process_dasgn_curr

    def process_defn(exp)
      in_method exp.shift, exp.file, exp.line do
        process_until_empty exp
      end
      s()
    end

    def process_defs(exp)
      process exp.shift # recv
      in_method "::#{exp.shift}", exp.file, exp.line do
        process_until_empty exp
      end
      s()
    end

    # TODO:  it's not clear to me whether this can be generated at all.
    def process_else(exp)
      add_to_score :branch
      penalize_by 0.1 do
        process_until_empty exp
      end
      s()
    end
    alias :process_rescue :process_else
    alias :process_when   :process_else

    def process_if(exp)
      add_to_score :branch
      process exp.shift # cond
      penalize_by 0.1 do
        process exp.shift # true
        process exp.shift # false
      end
      s()
    end

    def process_iter(exp)
      context = (self.context - [:class, :module, :scope])
      context = context.uniq.sort_by { |s| s.to_s }

      if context == [:block, :iter] or context == [:iter] then
        recv = exp.first

        # DSL w/ names. eg task :name do ... end
        if (recv[0] == :call and recv[1] == nil and recv.arglist[1] and
            [:lit, :str].include? recv.arglist[1][0]) then
          msg = recv[2]
          submsg = recv.arglist[1][1]
          in_class msg do                           # :task
            in_method submsg, exp.file, exp.line do # :name
              process_until_empty exp
            end
          end
          return s()
        end
      end

      add_to_score :branch

      exp.delete 0 # TODO: what is this?

      process exp.shift # no penalty for LHS

      penalize_by 0.1 do
        process_until_empty exp
      end

      s()
    end

    def process_lit(exp)
      value = exp.shift
      case value
      when 0, -1 then
        # ignore those because they're used as array indicies instead of
        # first/last
      when Integer then
        add_to_score :lit_fixnum
      when Float, Symbol, Regexp, Range then
        # do nothing
      else
        raise value.inspect
      end
      s()
    end

    def process_masgn(exp)
      add_to_score :assignment
      process_until_empty exp
      s()
    end

    def process_module(exp)
      in_class exp.shift do
        process_until_empty exp
      end
      s()
    end

    def process_sclass(exp)
      penalize_by 0.5 do
        process exp.shift # recv
        process_until_empty exp
      end

      add_to_score :sclass
      s()
    end

    def process_super(exp)
      add_to_score :super
      process_until_empty exp
      s()
    end

    def process_while(exp)
      add_to_score :branch
      penalize_by 0.1 do
        process exp.shift # cond
        process exp.shift # body
      end
      exp.shift # pre/post
      s()
    end
    alias :process_until :process_while

    def process_yield(exp)
      add_to_score :yield
      process_until_empty exp
      s()
    end

  end
end
