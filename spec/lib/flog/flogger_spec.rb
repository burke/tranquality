require 'spec_helper'
require 'flog'

describe Flog do

  let(:flogger) { Flog::Flogger.new }

  def util_process(sexp, score = -1, hash = {}, reset = true)
    flogger.process(sexp)

    @klass ||= "main"
    @meth  ||= "#none"

    unless score != -1 && hash.empty? then
      exp = {"#{@klass}#{@meth}" => hash}
      flogger.calls.should == exp
    end

    flogger.ensure_totals_calculated
    flogger.total_score.should be_within(0.01).of(score)
    flogger.reset_score_data if reset
  end

  def test_flog
    old_stdin = $stdin
    $stdin = StringIO.new "2 + 3"
    $stdin.rewind

    flogger.run "-"

    exp = { "main#none" => { :+ => 1.0, :lit_fixnum => 0.6 } }
    flogger.calls.should == exp

    flogger.ensure_totals_calculated
    flogger.options[:methods] or flogger.total_score.should == 1.6
    flogger.mass["-"].should == 4 # HACK: 3 is for an unpublished sexp fmt
  ensure
    $stdin = old_stdin
  end

  it 'add_to_score' do
    flogger.calls.should be_empty
    flogger.class_stack  << "Base" << "MyKlass"
    flogger.method_stack << "mymethod"
    flogger.add_to_score "blah", 42

    expected = {"MyKlass::Base#mymethod" => {"blah" => 42.0}}
    flogger.calls.should == expected

    flogger.add_to_score "blah", 2

    expected["MyKlass::Base#mymethod"]["blah"] = 44.0
    flogger.calls.should == expected
  end

  it 'average_per_method' do
    sexp = s(:and, s(:lit, :a), s(:lit, :b))
    util_process sexp, 1.0, {:branch => 1.0}, false

    flogger.average_per_method.should == 1.0
  end

  xit 'cls_expand_dirs_to_files' do
    expected = %w(lib/flogger.rb lib/flog_task.rb lib/gauntlet_flogger.rb)
    flogger.expand_dirs_to_files('lib').should == expected
    expected = %w(Rakefile)
    flogger.expand_dirs_to_files('Rakefile').should == expected
  end

  context 'capturing stdin' do
    before { @old_stdin = $stdin }
    after  { $stdin = @old_stdin }
  end

  context 'capturing stdin' do
    before { @old_stdin = $stdin }
    after  { $stdin = @old_stdin }
    it 'flog_erb' do
      $stdin = StringIO.new "2 + <%= blah %>"
      $stdin.rewind

      o, e = capture_io do
        flogger.run "-"
      end

      o.should == ""
      e.should match(/stupid lemmings/)
    end
  end

  it 'in_class' do
    flogger.class_stack.should be_empty

    flogger.in_class "xxx::yyy" do
      flogger.class_stack.should == ["xxx::yyy"]
    end

    flogger.class_stack.should be_empty
  end

  it 'in_method' do
    flogger.method_stack.should be_empty

    flogger.in_method "xxx", "file.rb", 42 do
      flogger.method_stack.should == ["xxx"]
    end

    flogger.method_stack.should be_empty

    expected = {"main#xxx" => "file.rb:42"}
    flogger.method_locations.should == expected
  end

  it 'klass_name' do
    flogger.klass_name.should == :main

    flogger.class_stack << "whatevs" << "flog"
    flogger.klass_name.should == "flog::whatevs"
  end

  it 'klass_name_sexp' do
    flogger.in_class s(:colon2, s(:const, :X), :Y) do
      flogger.klass_name.should == "X::Y"
    end

    flogger.in_class s(:colon3, :Y) do
      flogger.klass_name.should == "Y"
    end
  end

  it 'method_name' do
    flogger.method_name.should == "#none"

    flogger.method_stack << "whatevs"
    flogger.method_name.should == "#whatevs"
  end

  it 'method_name_cls' do
    flogger.method_name.should == "#none"

    flogger.method_stack << "::whatevs"
    flogger.method_name.should == "::whatevs"
  end

  it 'output_details' do
    flogger.options[:all] = true
    test_flog

    flogger.ensure_totals_calculated
    flogger.totals["main#something"] = 42.0

    o = StringIO.new
    flogger.output_details o

    expected = "\n     1.6: main#none\n"

    o.string.should == expected
    flogger.ensure_totals_calculated
    flogger.totals["main#none"].should == 1.6
  end

  it 'output_details_grouped' do
    test_flog

    o = StringIO.new
    flogger.output_details_grouped o

    expected = "\n     1.6: main total\n     1.6: main#none\n"

    o.string.should == expected
  end

  it 'output_details_methods' do
    flogger.options[:methods] = true

    test_flog

    flogger.ensure_totals_calculated
    flogger.totals["main#something"] = 42.0 # TODO: no sense... why no output?

    o = StringIO.new
    flogger.output_details o

    flogger.ensure_totals_calculated
    flogger.totals["main#none"].should == 0
  end

  it 'output_details_detailed' do
    flogger.options[:details] = true

    test_flog

    flogger.ensure_totals_calculated
    flogger.totals["main#something"] = 42.0

    o = StringIO.new
    flogger.output_details o, nil

    expected = "\n     1.6: main#none
     1.0:   +
     0.6:   lit_fixnum

"

    o.string.should == expected
    flogger.ensure_totals_calculated
    flogger.totals["main#none"].should == 1.6
  end

  # it 'process_until_empty' do
  #   flunk "no"
  # end

  it 'penalize_by' do
    flogger.penalization_factor.should == 1
    flogger.penalize_by 2 do
      flogger.penalization_factor.should == 3
    end
    flogger.penalization_factor.should == 1
  end

  it 'process_alias' do
    sexp = s(:alias, s(:lit, :a), s(:lit, :b))

    util_process sexp, 2.0, :alias => 2.0
  end

  it 'process_and' do
    sexp = s(:and, s(:lit, :a), s(:lit, :b))

    util_process sexp, 1.0, :branch => 1.0
  end

  it 'process_attrasgn' do
    sexp = s(:attrasgn,
             s(:call, nil, :a, s(:arglist)),
             :[]=,
             s(:arglist,
               s(:splat,
                 s(:call, nil, :b, s(:arglist))),
               s(:call, nil, :c, s(:arglist))))

    util_process(sexp, 3.162,
                 :c => 1.0, :b => 1.0, :a => 1.0, :assignment => 1.0)
  end

  # it 'process_attrset' do
  #   sexp = s(:attrset, :@writer)
  #
  #   util_process(sexp, 3.162,
  #                :c => 1.0, :b => 1.0, :a => 1.0, :assignment => 1.0)
  #
  #   flunk "Not yet"
  # end

  it 'process_block' do
    sexp = s(:block, s(:and, s(:lit, :a), s(:lit, :b)))

    util_process sexp, 1.1, :branch => 1.1 # 10% penalty over process_and
  end

  it 'process_block_pass' do
    sexp = s(:call, nil, :a,
             s(:arglist,
               s(:block_pass,
                 s(:call, nil, :b, s(:arglist)))))

    util_process(sexp, 9.4,
                 :a              => 1.0,
                 :block_pass     => 1.2,
                 :b              => 1.2,
                 :to_proc_normal => 6.0)
  end

  it 'process_block_pass_colon2' do
    sexp = s(:call, nil, :a,
             s(:arglist,
               s(:block_pass,
                 s(:colon2, s(:const, :A), :B))))

    util_process(sexp, 2.2,
                 :a              => 1.0,
                 :block_pass     => 1.2)
  end

  it 'process_block_pass_iter' do
    sexp = s(:block_pass,
             s(:iter, s(:call, nil, :lambda, s(:arglist)), nil, s(:lit, 1)))

    util_process(sexp, 12.316,
                 :lit_fixnum    =>  0.275,
                 :block_pass    =>  1.0,
                 :lambda        =>  1.0,
                 :branch        =>  1.0,
                 :to_proc_icky! => 10.0)
  end

  it 'process_block_pass_lasgn' do
    sexp = s(:block_pass,
             s(:lasgn,
               :b,
               s(:iter, s(:call, nil, :lambda, s(:arglist)), nil, s(:lit, 1))))

    util_process(sexp, 17.333,
                 :lit_fixnum    =>  0.275,
                 :block_pass    =>  1.0,
                 :lambda        =>  1.0,
                 :assignment    =>  1.0,
                 :branch        =>  1.0,
                 :to_proc_lasgn => 15.0)
  end

  it 'process_call' do
    sexp = s(:call, nil, :a, s(:arglist))
    util_process sexp, 1.0, :a => 1.0
  end

  it 'process_case' do
    case :a
    when :a
      42
    end


    sexp = s(:case,
             s(:lit, :a),
             s(:when, s(:array, s(:lit, :a)), s(:nil)),
             nil)

    util_process sexp, 2.1, :branch => 2.1
  end

  it 'process_class' do
    @klass = "X::Y"

    sexp = s(:class,
             s(:colon2, s(:const, :X), :Y), nil,
             s(:scope, s(:lit, 42)))

    util_process sexp, 0.25, :lit_fixnum => 0.25
  end

  # TODO:
  # 392:  alias :process_or :process_and
  # 475:  alias :process_iasgn :process_dasgn_curr
  # 476:  alias :process_lasgn :process_dasgn_curr
  # 501:  alias :process_rescue :process_else
  # 502:  alias :process_when   :process_else
  # 597:  alias :process_until :process_while


  # it 'process_dasgn_curr' do
  #   flunk "Not yet"
  # end

  it 'process_defn' do
    @meth = "#x"

    sexp = s(:defn, :x,
             s(:args, :y),
             s(:scope,
               s(:block,
                 s(:lit, 42))))

    util_process sexp, 0.275, :lit_fixnum => 0.275
  end

  it 'process_defs' do
    @meth = "::x" # HACK, I don't like this

    sexp = s(:defs, s(:self), :x,
             s(:args, :y),
             s(:scope,
               s(:block,
                 s(:lit, 42))))

    util_process sexp, 0.275, :lit_fixnum => 0.275
  end

  # FIX: huh? over-refactored?
  # it 'process_else' do
  #   flunk "Not yet"
  # end

  it 'process_if' do
    sexp = s(:if,
             s(:call, nil, :b, s(:arglist)), # outside block, not penalized
             s(:call, nil, :a, s(:arglist)), nil)

    util_process sexp, 2.326, :branch => 1.0, :b => 1.0, :a => 1.1
  end

  it 'process_iter' do
    sexp = s(:iter,
             s(:call, nil, :loop, s(:arglist)), nil,
             s(:if, s(:true), s(:break), nil))

    util_process sexp, 2.326, :loop => 1.0, :branch => 2.1
  end

  it 'process_iter_dsl' do
    # task :blah do
    #   something
    # end

    sexp = s(:iter,
             s(:call, nil, :task, s(:arglist, s(:lit, :blah))),
             nil,
             s(:call, nil, :something, s(:arglist)))

    @klass, @meth = "task", "#blah"

    util_process sexp, 2.0, :something => 1.0, :task => 1.0
  end

  it 'process_iter_dsl_regexp' do
    # task /regexp/ do
    #   something
    # end

    sexp = s(:iter,
             s(:call, nil, :task, s(:arglist, s(:lit, /regexp/))),
             nil,
             s(:call, nil, :something, s(:arglist)))

    @klass, @meth = "task", "#/regexp/"

    util_process sexp, 2.0, :something => 1.0, :task => 1.0
  end

  it 'process_lit' do
    sexp = s(:lit, :y)
    util_process sexp, 0.0
  end

  it 'process_lit_int' do
    sexp = s(:lit, 42)
    util_process sexp, 0.25, :lit_fixnum => 0.25
  end

  it 'process_lit_float # and other lits' do
    sexp = s(:lit, 3.1415) # TODO: consider penalizing floats if not in cdecl
    util_process sexp, 0.0
  end

  it 'process_lit_bad' do
    expect {
      flogger.process s(:lit, Object.new)
    }.to raise_error RuntimeError
  end

  it 'process_masgn' do
    sexp = s(:masgn,
             s(:array, s(:lasgn, :a), s(:lasgn, :b)),
             s(:to_ary, s(:call, nil, :c, s(:arglist))))

    util_process sexp, 3.162, :c => 1.0, :assignment => 3.0
  end

  it 'process_module' do
    @klass = "X::Y"

    sexp = s(:module,
             s(:colon2, s(:const, :X), :Y),
             s(:scope, s(:lit, 42)))

    util_process sexp, 0.25, :lit_fixnum => 0.25
  end

  it 'process_sclass' do
    sexp = s(:sclass, s(:self), s(:scope, s(:lit, 42)))
    util_process sexp, 5.375, :sclass => 5.0, :lit_fixnum => 0.375
  end

  it 'process_super' do
    sexp = s(:super)
    util_process sexp, 1.0, :super => 1.0

    sexp = s(:super, s(:lit, 42))
    util_process sexp, 1.25, :super => 1.0, :lit_fixnum => 0.25
  end

  it 'process_while' do
    sexp = s(:while,
             s(:call, nil, :a, s(:arglist)),
             s(:call, nil, :b, s(:arglist)),
             true)

    util_process sexp, 2.417, :branch => 1.0, :a => 1.1, :b => 1.1
  end

  it 'process_yield' do
    sexp = s(:yield)
    util_process sexp, 1.00, :yield => 1.0

    sexp = s(:yield, s(:lit, 4))
    util_process sexp, 1.25, :yield => 1.0, :lit_fixnum => 0.25

    sexp = s(:yield, s(:lit, 42), s(:lit, 24))
    util_process sexp, 1.50, :yield => 1.0, :lit_fixnum => 0.50
  end

  it 'report' do
    test_flog

    o = StringIO.new
    flogger.report o

    expected = "     1.6: flog total
     1.6: flog/method average

     1.6: main#none
"

    o.string.should == expected
  end

  context 'capturing stdin' do
    before { @old_stdin = $stdin }
    after  { $stdin = @old_stdin }
    it 'report_all' do
      $stdin = StringIO.new "2 + 3"
      $stdin.rewind

      flogger.run "-"
      flogger.ensure_totals_calculated
      flogger.totals["main#something"] = 42.0

      exp = { "main#none" => { :+ => 1.0, :lit_fixnum => 0.6 } }
      flogger.calls.should == exp

      flogger.options[:all] = true

      flogger.options[:methods] or flogger.total_score.should == 1.6
      flogger.mass["-"].should == 4 # HACK: 3 is for an unpublished sexp fmt

      o = StringIO.new
      flogger.report o

      expected = "     1.6: flog total\n     1.6: flog/method average\n\n     1.6: main#none\n"

      o.string.should == expected
      # FIX: add thresholded output
    end
  end

  it 'report_group' do
    # TODO: add second group to ensure proper output
    flogger.options[:group] = true

    test_flog

    o = StringIO.new
    flogger.report o

    expected = "     1.6: flog total
     1.6: flog/method average

     1.6: main total
     1.6: main#none
"

    o.string.should == expected
  end

  it 'score_method' do
    flogger.score_method(:blah       => 3.0).should == 3.0
    flogger.score_method(:assignment => 4.0).should == 4.0
    flogger.score_method(:branch     => 2.0).should == 2.0
    flogger.score_method(:blah       => 3.0, :branch => 4.0).should == 5.0
  end

  it 'signature' do
    flogger.signature.should == "main#none"

    flogger.class_stack << "X"
    flogger.signature.should == "X#none"

    flogger.method_stack << "y"
    flogger.signature.should == "X#y"

    flogger.class_stack.shift
    flogger.signature.should == "main#y"
  end

  it 'total' do
    flogger.add_to_score "blah", 2
    flogger.ensure_totals_calculated
    flogger.total_score.should == 2.0
  end

end
