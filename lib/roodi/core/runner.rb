require 'yaml'
require 'ruby_parser'
require 'sexp_processor'
require 'tranquality/sexp_extensions'

require 'roodi/core/checking_visitor'
require 'roodi/core/parser'

module Roodi
  module Core
    class Runner
      DEFAULT_CONFIG = File.join(File.dirname(__FILE__), "..", "..", "..", "roodi.yml")

      attr_writer :config

      def initialize(*checks)
        @config = DEFAULT_CONFIG
        @checks = checks unless checks.empty?
        @parser = Parser.new
      end

      def check(filename, content)
        @checks ||= load_checks
        @checker ||= CheckingVisitor.new(@checks)
        @checks.each {|check| check.start_file(filename)}
        node = parse(filename, content)
        node.accept(@checker) if node
        @checks.each {|check| check.end_file(filename)}
      end

      def check_content(content, filename = "dummy-file.rb")
        check(filename, content)
      end

      def check_file(filename)
        check(filename, File.read(filename))
      end

      def errors
        @checks ||= []
        all_errors = @checks.collect {|check| check.errors}
        all_errors.flatten
      end

      private

      def parse(filename, content)
        begin
          @parser.parse(content, filename)
        rescue Exception => e
          puts "#{filename} looks like it's not a valid Ruby file.  Skipping..." if ENV["ROODI_DEBUG"]
          nil
        end
      end

      def load_checks
        check_objects = []
        checks = YAML.load_file @config
        checks.each do |check|
          opts = check[1] || {}
          klass = eval("Roodi::Checks::#{check[0]}")
          check_objects << (opts.empty? ? klass.new : klass.new(opts))
        end
        check_objects
      end
    end
  end
end
