require 'sexp_processor'
require 'ruby_parser'

require 'flog/process_methods'
require 'flog/process_method_helpers'
require 'flog/reporting'

module Flog
  class Flogger < SexpProcessor
    include Flog::ProcessMethods
    include Flog::ProcessMethodHelpers
    include Flog::Reporting

    attr_accessor :penalization_factor
    attr_reader :calls, :class_stack, :method_stack, :mass
    attr_reader :method_locations

    def reset_score_data
      @totals     = @total_score = nil
      @penalization_factor = 1.0
      @calls      = Hash.new { |h,k| h[k] = Hash.new 0 }
    end

    def initialize
      super()
      @class_stack         = []
      @method_stack        = []
      @method_locations    = {}
      @mass                = {}
      @parser              = Ruby19Parser.new
      self.auto_shift_type = true
      reset_score_data
    end

    def visit(ast, file)
      mass[file] = ast.mass
      process(ast)
    end
  end
end
