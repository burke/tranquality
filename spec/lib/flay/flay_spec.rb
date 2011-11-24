require 'flay'
require 'tranquality/sexp_extensions'

describe Flay do

  before {
    # a(1) { |c| d }
    @s = s(:iter,
           s(:call, nil, :a, s(:arglist, s(:lit, 1))),
           s(:lasgn, :c),
           s(:call, nil, :d, s(:arglist)))
  }

  it 'structural_hash' do
    hash = s(:iter,
             s(:call, s(:arglist, s(:lit))),
             s(:lasgn),
             s(:call, s(:arglist))).hash

    @s.structural_hash.should == hash
    @s.deep_clone.structural_hash.should == hash
  end

  it 'all_structural_hashes' do
    s = s(:iter,
          s(:call, s(:arglist, s(:lit))),
          s(:lasgn),
          s(:call, s(:arglist)))

    expected = [
                s[1]      .hash,
                s[1][1]   .hash,
                s[1][1][1].hash,
                s[2]      .hash,
                s[3]      .hash,
                s[3][1]   .hash,
               ].sort

    @s.all_structural_subhashes.sort.uniq.should == expected

    x = []

    @s.deep_each do |o|
      x << o.structural_hash
    end

    x.sort.uniq.should == expected
  end

  it 'visit' do
    flay = Flay.new

    s = Ruby19Parser.new.process <<-RUBY
      def x(n)
        if n % 2 == 0
          return n
        else
          return n + 1
        end
      end
    RUBY

    expected = [[:block],
                # HACK [:defn],
                [:scope]] # only ones big enough

    flay.visit s, "-"

    actual = flay.hashes.values.map { |sexps| sexps.map { |sexp| sexp.first } }

    actual.sort_by { |a| a.first.to_s }.should == expected
  end

  it 'visit more complicated sexp' do
    flay = Flay.new(:mass => 1)

    s = Ruby19Parser.new.process <<-RUBY
      def x(n)
        if n % 2 == 0
          return n
        else
          return n + 1
        end
      end
    RUBY

    expected = [[:arglist, :arglist, :arglist],
                [:block],
                [:call, :call],
                [:call],
                [:if],
                [:return],
                [:return],
                [:scope]]

    flay.visit s, '-'

    actual = flay.hashes.values.map { |sexps| sexps.map { |sexp| sexp.first } }

    actual.sort_by { |a| a.inspect }.should == expected
  end

  it 'process_sexp_no_structure' do
    flay = Flay.new(:mass => 1)
    flay.visit s(:lit, 1), '-'

    flay.hashes.should be_empty
  end

  it 'reports correctly' do
    flay = Flay.new

    s = Ruby19Parser.new.process <<-RUBY
      class Dog
        def x
          if $some_code == @other_code
            do_thing_1 and return [1,3,4,6,7,8,3]
          else
            do_thing_2
          end
          if $some_code == @other_code
            do_thing_1 and return [1,3,4,6,7,8,3]
          else
            do_thing_2
          end
          return "Hello"
        end
      end
      class Cat
        def y
          return "Hello"
        end
      end
    RUBY

    flay.visit s, "myfile"
    flay.analyze

    flay.report.should == {:total_score=>76, :details=>[{:locations=>[["(string)", 3], ["(string)", 8]], :mass=>76, :similarity=>:identical, :bonus=>2}]}
  end
end
