require 'ruby_parser'
require 'sexp_processor'

require 'tranquality/parser'

module Tranquality
  class Runner

    def initialize
      @parse_errors = {}
    end

    def run(*dirs)
      self.class.expand_dirs_to_files(*dirs).each do |file|
        process_file(file)
      end
      analyze
    end

    def self.expand_dirs_to_files(*dirs)
      extensions = ['rb']

      dirs.flatten.map { |p|
        if File.directory? p then
          Dir[File.join(p, '**', "*.{#{extensions.join(',')}}")]
        else
          p
        end
      }.flatten
    end

    def parser
      if defined?(Ruby19Parser)
        Ruby19Parser.new
      else
        RubyParser.new
      end
    end

    def process_file(file)
      ast = parse_file(file)
      visit_all(ast, file)
    rescue Tranquality::Parser::ParseError => e
      @parse_errors[file] = e
    end

    def parse_file(file)
      Tranquality::Parser.new.parse(read_file(file), file)
    end

    def read_file(file)
      file == '-' ? $stdin.read : File.read(file)
    end

    def report
      puts flog.report.inspect
      puts "="*100
      puts flay.report.inspect
      puts "="*100
      puts @parse_errors.inspect
    end

    def visit_all(ast, file)
      visitors.each do |visitor|
        ast.accept(visitor, file)
      end
    end

    def visitors
      [flay, flog]
    end

    def flog
      @flog ||= Flog::Flogger.new
    end

    def flay
      @flay ||= Flay.new
    end

    def analyze
      flay.analyze
    end

  end
end
