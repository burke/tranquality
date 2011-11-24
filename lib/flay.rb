require 'sexp_processor'
require 'flay/reporter'
require 'tranquality/sexp_extensions'

class Flay
  include Flay::Reporter

  def visit(ast, file)
    process_sexp(ast) if ast
  end

  def self.default_options
    {:mass => 16}
  end

  attr_accessor :mass_threshold, :total, :identical, :masses
  attr_reader :hashes, :options

  def initialize(options = Flay.default_options)
    @hashes = Hash.new { |h,k| h[k] = [] }

    @options        = options
    @identical      = {}
    @masses         = {}
    @total          = 0
    @mass_threshold = @options[:mass]
  end

  def analyze
    prune

    hashes.each do |hash, nodes|
      identical[hash] = nodes[1..-1].all? { |n| n == nodes.first }
      masses[hash] = nodes.first.mass * nodes.size
      masses[hash] *= (nodes.size) if identical[hash]
      self.total += masses[hash]
    end
  end

  private

  def process_sexp(pt)
    pt.deep_each do |node|
      next unless node.any? { |sub| Sexp === sub }
      next if node.mass < self.mass_threshold

      self.hashes[node.structural_hash] << node
    end
  end

  def prune
    # prune trees that aren't duped at all, or are too small
    hashes.delete_if { |_, nodes| nodes.size == 1 }

    # extract all subtree hashes from all nodes
    all_hashes = {}
    hashes.values.each do |nodes|
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

