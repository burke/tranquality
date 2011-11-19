require 'spec_helper'
require 'flog/option_parser'

describe Flog::OptionParser do
  it 'parses options' do
    # defaults
    opts = Flog::OptionParser.parse
    opts[:quiet].should be_true
    opts[:continue].should be_false

    {
      "-a"             => :all,
      "--all"          => :all,
      "-b"             => :blame,
      "--blame"        => :blame,
      "-c"             => :continue,
      "--continue"     => :continue,
      "-d"             => :details,
      "--details"      => :details,
      "-g"             => :group,
      "--group"        => :group,
      "-m"             => :methods,
      "--methods-only" => :methods,
      "-q"             => :quiet,
      "--quiet"        => :quiet,
      "-s"             => :score,
      "--score"        => :score,
      "-v"             => :verbose,
      "--verbose"      => :verbose,
    }.each do |key, val|
      Flog::OptionParser.parse(key)[val].should be_true
    end
  end

  describe 'include path' do
    before { @old_path = $:.dup   }
    after  { $:.replace @old_path }

    it 'recognizes the form with no interstitial space' do
      Flog::OptionParser.parse("-Ia,b,c")
      $:.should == @old_path + %w(a b c)
    end

    it 'recognizes the form with an interstitial space' do
      Flog::OptionParser.parse(["-I", "d,e,f"])
      $:.should == @old_path + %w(d e f)
    end

    it 'recognizes a complex combination of include formats' do
      Flog::OptionParser.parse(["-I", "g", "-Ih"])
      $:.should == @old_path + %w(g h)
    end
  end

  describe 'help option' do

    let(:dummy_exception) { stub }

    before {
      def Flog.exit
        raise dummy_exception
      end
    }

    it 'terminates execution after ____' do
      expect {
        capture_io { Flog::OptionParser.parse "-h" }
      }.to raise_error SystemExit

      #  assert_equal "happy", ex.message
      #  assert_match(/methods-only/, o)
      #  assert_equal "", e

    end


  end

end
