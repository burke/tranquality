require 'ruby_parser'

module Tranquality
  class Parser
    def parse(content, filename)
      silence_stream(STDERR) do
        return silent_parse(content, filename)
      end
    end

    private

    def silence_stream(stream)
      old_stream = stream.dup
      stream.reopen(RUBY_PLATFORM =~ /mswin/ ? 'NUL:' : '/dev/null')
      stream.sync = true
      yield
    ensure
      stream.reopen(old_stream)
    end

    def parser_class
      if defined?(Ruby19Parser)
        Ruby19Parser
      else
        RubyParser
      end
    end

    def silent_parse(content, filename)
      @parser ||= parser_class.new
      @parser.parse(content, filename)
    end
  end
end
