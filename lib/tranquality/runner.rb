class Sexp
  def accept(visitor, file = nil)
    visitor.visit(self, file)
  end
end

module Tranquality
  class Runner

    def run(*dirs)
      self.class.expand_dirs_to_files(*dirs).each do |file|
        ast = parse_file(file)
        visit_all(ast, file)
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

    def parse_file(file)
      parser.process(read_file(file), file)
    end

    def read_file(file)
      file == '-' ? $stdin.read : File.read(file)
    end

    def report
      puts flog.report.inspect
      puts "="*100
      puts flay.report.inspect
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
