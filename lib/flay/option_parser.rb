require 'optparse'
require 'flay/version'

class Flay
  module OptionParser
    def self.parse
      options = Flay.default_options

      ::OptionParser.new do |opts|
        opts.banner  = 'flay [options] files_or_dirs'
        opts.version = Flay::VERSION

        opts.separator ""
        opts.separator "Specific options:"
        opts.separator ""

        opts.on('-h', '--help', 'Display this help.') do
          puts opts
          exit
        end

        opts.on('-f', '--fuzzy', "DEAD: fuzzy similarities.") do
          abort "--fuzzy is no longer supported. Sorry. It sucked."
        end

        opts.on('-m', '--mass MASS', Integer, "Sets mass threshold") do |m|
          options[:mass] = m.to_i
        end

        opts.on('-v', '--verbose', "Verbose. Show progress processing files.") do
          options[:verbose] = true
        end

        opts.on('-d', '--diff', "Diff Mode. Display N-Way diff for ruby.") do
          options[:diff] = true
        end

        opts.on('-s', '--summary', "Summarize. Show flay score per file only.") do
          options[:summary] = true
        end

        extensions = ['rb']

        opts.separator ""
        opts.separator "Known extensions: #{extensions.join(', ')}"

        begin
          opts.parse!
        rescue => e
          abort "#{e}\n\n#{opts}"
        end
      end

      options
    end

  end
end
