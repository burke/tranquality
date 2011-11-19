lib = File.expand_path('../../lib', __FILE__)
$:.unshift(lib) unless $:.include?(lib)

unless defined?(SexpProcessor)
  class SexpProcessor ; end
end

def capture_io
  require 'stringio'

  orig_stdout, orig_stderr         = $stdout, $stderr
  captured_stdout, captured_stderr = StringIO.new, StringIO.new
  $stdout, $stderr                 = captured_stdout, captured_stderr

  yield

  return captured_stdout.string, captured_stderr.string
ensure
  $stdout = orig_stdout
  $stderr = orig_stderr
end

def util_process sexp, score = -1, hash = {}
  setup
  @flog.process sexp

  @klass ||= "main"
  @meth  ||= "#none"

  unless score != -1 && hash.empty? then
    exp = {"#{@klass}#{@meth}" => hash}
    assert_equal exp, @flog.calls
  end

  assert_in_delta score, @flog.total
end


