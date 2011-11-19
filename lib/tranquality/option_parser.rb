require 'optparse'

module Tranquality
  module OptionParser
    def self.parse args = ARGV
      options = {
        :quiet    => true,
        :continue => false,
      }

      ::OptionParser.new do |opts|
        opts.separator "Standard options:"

        opts.on("-a", "--all", "Display all flog results, not top 60%.") do
          options[:all] = true
        end

        opts.on("-b", "--blame", "Include blame information for methods.") do
          options[:blame] = true
        end

        opts.on("-c", "--continue", "Continue despite syntax errors.") do
          options[:continue] = true
        end

        opts.on("-d", "--details", "Show method details.") do
          options[:details] = true
        end

        opts.on("-g", "--group", "Group and sort by class.") do
          options[:group] = true
        end

        opts.on("-h", "--help", "Show this message.") do
          puts opts
          exit
        end

        opts.on("-I dir1,dir2,dir3", Array, "Add to LOAD_PATH.") do |dirs|
          dirs.each do |dir|
            $: << dir
          end
        end

        opts.on("-m", "--methods-only", "Skip code outside of methods.") do
          options[:methods] = true
        end

        opts.on("-q", "--quiet", "Don't show method details. [default]") do
          options[:quiet] = true
        end

        opts.on("-s", "--score", "Display total score only.") do
          options[:score] = true
        end

        opts.on("-v", "--verbose", "Display progress during processing.") do
          options[:verbose] = true
        end

      end.parse! Array(args)

      options
    end
  end
end
