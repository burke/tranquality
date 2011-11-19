#!/usr/bin/env ruby -w

require 'optparse'
require 'rubygems'
require 'sexp_processor'
require 'ruby_parser'

require 'flay/reporter'
require 'flay/sexp_extensions'

class String
  attr_accessor :group
end

class Flay
  include Flay::Reporter

  def self.default_options
    {
      :diff    => false,
      :mass    => 16,
      :summary => false,
      :verbose => false,
    }
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

  attr_accessor :mass_threshold, :total, :identical, :masses
  attr_reader :hashes, :option

  def initialize(option = nil)
    @option = option || Flay.default_options
    @hashes = Hash.new { |h,k| h[k] = [] }

    @identical      = {}
    @masses         = {}
    @total          = 0
    @mass_threshold = @option[:mass]

    require 'ruby2ruby' if @option[:diff]
  end

  def process(*files)
    files.each do |file|
      process_file(file)
    end
    analyze
  end

  def process_file(file)
    warn "Processing #{file}" if option[:verbose]

    ext = File.extname(file).sub(/^\./, '')
    ext = "rb" if ext.nil? || ext.empty?
    msg = "process_#{ext}"

    unless respond_to? msg then
      warn "  Unknown file type: #{ext}, defaulting to ruby"
      msg = "process_rb"
    end

    begin
      sexp = parse_file(msg, file)
      process_sexp(sexp) if sexp
    rescue SyntaxError => e
      warn "  skipping #{file}: #{e.message}"
    end
  end

  def parse_file(msg, file)
    send(msg, file)
  rescue => e
    warn "  #{e.message.strip}"
    warn "  skipping #{file}"
    nil
  end

  def analyze
    self.prune

    self.hashes.each do |hash,nodes|
      identical[hash] = nodes[1..-1].all? { |n| n == nodes.first }
      masses[hash] = nodes.first.mass * nodes.size
      masses[hash] *= (nodes.size) if identical[hash]
      self.total += masses[hash]
    end
  end

  def process_rb(file)
    Ruby19Parser.new.process(File.read(file), file)
  end

  def process_sexp(pt)
    pt.deep_each do |node|
      next unless node.any? { |sub| Sexp === sub }
      next if node.mass < self.mass_threshold

      self.hashes[node.structural_hash] << node
    end
  end

  def prune
    # prune trees that aren't duped at all, or are too small
    self.hashes.delete_if { |_,nodes| nodes.size == 1 }

    # extract all subtree hashes from all nodes
    all_hashes = {}
    self.hashes.values.each do |nodes|
      nodes.each do |node|
        node.all_structural_subhashes.each do |h|
          all_hashes[h] = true
        end
      end
    end

    # nuke subtrees so we show the biggest matching tree possible
    self.hashes.delete_if { |h,_| all_hashes[h] }
  end

end

