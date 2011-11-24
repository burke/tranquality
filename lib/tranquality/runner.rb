class Sexp
  def accept(visitor, file = nil)
    visitor.visit(self, file)
  end
end

module Tranquality
  class Runner

    def read_file(file)
      file == '-' ? $stdin.read : File.read(file)
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

    def initialize(options)
      @options = options
    end

    def run(*dirs)
      self.class.expand_dirs_to_files(*dirs).each do |file|
        ast = Ruby19Parser.new.process(read_file(file), file)
        do_stuff_with(ast, file)
      end
      do_stuff_at_end
    end

    def report
      puts flog.report.inspect
      puts "="*100
      puts flay.report.inspect
    end

    def flog
      @flog ||= Flog::Flogger.new
    end

    def flay
      @flay ||= Flay.new
    end

    def do_stuff_with(ast, file)
      ast.accept(flay, file)
      ast.accept(flog, file)
    end

    def do_stuff_at_end
      flay.analyze
    end

  end
end
