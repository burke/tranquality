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
    attr_reader :calls, :options, :class_stack, :method_stack, :mass
    attr_reader :method_locations

    # Flog the given files or directories. Smart. Deals with "-", syntax
    # errors, and traversing subdirectories intelligently.
    def run(*files_or_dirs)
      files = self.class.expand_dirs_to_files(*files_or_dirs)

      files.each do |file|
        begin
          # TODO: replace File.open to deal with "-"
          ruby = file == '-' ? $stdin.read : File.read(file)
          warn "** flogging #{file}" if options[:verbose]

          ast = @parser.process(ruby, file)
          next unless ast
          mass[file] = ast.mass
          process ast
        rescue RegexpError, SyntaxError, Racc::ParseError => e
          if e.inspect =~ /<%|%>/ or ruby =~ /<%|%>/ then
            warn "#{e.inspect} at #{e.backtrace.first(5).join(', ')}"
            warn "\n...stupid lemmings and their bad erb templates... skipping"
          else
            warn "ERROR: parsing ruby file #{file}"
            unless options[:continue] then
              warn "ERROR! Aborting. You may want to run with --continue."
              raise e
            end
            warn "#{e.class}: #{e.message.strip} at:"
            warn "  #{e.backtrace.first(5).join("\n  ")}"
          end
        end
      end
    end

    def initialize(options = {})
      super()
      @options             = options
      @class_stack         = []
      @method_stack        = []
      @method_locations    = {}
      @mass                = {}
      @parser              = Ruby19Parser.new
      self.auto_shift_type = true
      self.reset_score_data
    end

    def reset_score_data
      @totals     = @total_score = nil
      @penalization_factor = 1.0
      @calls      = Hash.new { |h,k| h[k] = Hash.new 0 }
    end

    def self.expand_dirs_to_files(*dirs)
      extensions = OPTIONS[:extensions]

      dirs.flatten.map { |p|
        if File.directory? p then
          Dir[File.join(p, '**', "*.{#{extensions.join(',')}}")]
        else
          p
        end
      }.flatten.sort
    end

  end
end
