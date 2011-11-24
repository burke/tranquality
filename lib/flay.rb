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
    calculate_results
  end

  private

  def process_sexp(pt)
    pt.deep_each do |node|
      next unless node.any? { |sub| Sexp === sub }
      next if node.mass < self.mass_threshold

      self.hashes[node.structural_hash] << node
    end
  end

  def calculate_results
    hashes.each do |hash, nodes|
      identical[hash] = nodes[1..-1].all? { |n| n == nodes.first }
      masses[hash] = nodes.first.mass * nodes.size
      masses[hash] *= (nodes.size) if identical[hash]
      self.total += masses[hash]
    end
  end

  def prune
    prune_trees_that_are_not_duped
    prune_subtrees_of_duped_trees
  end

  def prune_subtrees_of_duped_trees
    duped_subtree_hashes = subtree_hashes_of_all_duped_nodes
    hashes.delete_if { |h, _| duped_subtree_hashes[h] }
  end

  def prune_trees_that_are_not_duped
    hashes.delete_if { |_, nodes| nodes.size == 1 }
  end

  def subtree_hashes_of_all_duped_nodes
    subtree_hashes = {}
    hashes.values.each do |nodes|
      nodes.each do |node|
        node.all_structural_subhashes.each do |h|
          subtree_hashes[h] = true
        end
      end
    end
    subtree_hashes
  end

end

