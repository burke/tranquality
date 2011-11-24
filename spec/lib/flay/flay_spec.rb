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

    Flay.new.all_structural_subhashes(@s).sort.uniq.should == expected

    x = []

    Flay.new.sexp_deep_each(@s) do |o|
      x << o.structural_hash
    end

    x.sort.uniq.should == expected
  end

  it 'process_sexp' do
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

    flay.process_sexp s

    actual = flay.hashes.values.map { |sexps| sexps.map { |sexp| sexp.first } }

    actual.sort_by { |a| a.first.to_s }.should == expected
  end

  it 'process_sexp_full' do
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

    flay.process_sexp s

    actual = flay.hashes.values.map { |sexps| sexps.map { |sexp| sexp.first } }

    actual.sort_by { |a| a.inspect }.should == expected
  end

  it 'process_sexp_no_structure' do
    flay = Flay.new(:mass => 1)
    flay.process_sexp s(:lit, 1)

    flay.hashes.should be_empty
  end

  def test_report
    # make sure we run through options parser
    $*.clear
    $* << "-d"
    $* << "--mass=1"
    $* << "-v"

    opts = nil
    capture_io do # ignored
      opts = Flay.parse_options
    end

    flay = Flay.new opts

    s = Ruby19Parser.new.process <<-RUBY
      class Dog
        def x
          return "Hello"
        end
      end
      class Cat
        def y
          return "Hello"
        end
      end
    RUBY

    flay.process_sexp s
    flay.analyze

    out, err = capture_io do
      flay.report nil
    end

    exp = <<-END.gsub(/\d+/, "N").gsub(/^ {6}/, "")
      Total score (lower is better) = 16


      1) Similar code found in :class (mass = 16)
        A: (string):1
        B: (string):6

      A: class Dog
      B: class Cat
      A:   def x
      B:   def y
             return \"Hello\"
           end
         end
    END

    err.should == ''
    out.gsub(/\d+/, "N").should == exp
  end
end
