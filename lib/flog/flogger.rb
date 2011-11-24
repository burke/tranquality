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

    def run(*files_or_dirs)
      self.class.expand_dirs_to_files(*files_or_dirs).each do |file|
        run_file(file)
      end
    end

    def reset_score_data
      @totals     = @total_score = nil
      @penalization_factor = 1.0
      @calls      = Hash.new { |h,k| h[k] = Hash.new 0 }
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
      reset_score_data
    end

    def accept(ast, file)
      mass[file] = ast.mass
      process(ast)
    end

    private

    def run_file(file)
      ruby = read_file(file)
      warn "** flogging #{file}" if options[:verbose]

      if ast = parse_file(ruby, file)
        mass[file] = ast.mass
        process(ast)
      end
    end

    def parse_file(ruby, file)
      @parser.process(ruby, file)
    rescue RegexpError, SyntaxError, Racc::ParseError => e
      handle_run_error(e, ruby)
    end

    def handle_run_error(e, ruby)
      if e.inspect =~ /<%|%>/ or ruby =~ /<%|%>/ then
        warn "#{e.inspect} at #{e.backtrace.first(5).join(', ')}"
        warn "\nBroken ERB template. Skipping."
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

    def read_file(file)
      file == '-' ? $stdin.read : File.read(file)
    end

    def self.expand_dirs_to_files(*dirs)
      extensions = OPTIONS[:extensions]
      dirs.flatten.map { |file_or_dir|
        if File.directory?(file_or_dir)
          files_in_directory_with_extensions(file_or_dir, extensions)
        else
          file_or_dir
        end
      }.flatten.sort
    end

    def files_in_directory_with_extensions(dir, extensions)
      Dir[File.join(dir, '**', "*.{#{extensions.join(',')}}")]
    end

  end
end
