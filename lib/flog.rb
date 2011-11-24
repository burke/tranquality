require 'flog/flogger'

module Flog
  THRESHOLD = 0.60
  SCORES = Hash.new(1)
  BRANCHING = [ :and, :case, :else, :if, :or, :rescue, :until, :when, :while ]

  # Various non-call constructs
  OTHER_SCORES = {
    :alias          => 2,
    :assignment     => 1,
    :block          => 1,
    :block_pass     => 1,
    :branch         => 1,
    :lit_fixnum     => 0.25,
    :sclass         => 5,
    :super          => 1,
    :to_proc_icky!  => 10,
    :to_proc_lasgn  => 15,
    :to_proc_normal => 5,
    :yield          => 1,
  }

  # Eval forms
  SCORES.merge!(:define_method => 5,
                :eval          => 5,
                :module_eval   => 5,
                :class_eval    => 5,
                :instance_eval => 5)

  # Various "magic" usually used for "clever code"
  SCORES.merge!(:alias_method               => 2,
                :extend                     => 2,
                :include                    => 2,
                :instance_method            => 2,
                :instance_methods           => 2,
                :method_added               => 2,
                :method_defined?            => 2,
                :method_removed             => 2,
                :method_undefined           => 2,
                :private_class_method       => 2,
                :private_instance_methods   => 2,
                :private_method_defined?    => 2,
                :protected_instance_methods => 2,
                :protected_method_defined?  => 2,
                :public_class_method        => 2,
                :public_instance_methods    => 2,
                :public_method_defined?     => 2,
                :remove_method              => 2,
                :send                       => 3,
                :undef_method               => 2)

  # Calls that are ALMOST ALWAYS ABUSED!
  SCORES.merge!(:inject => 2)

  NO_CLASS = :main
  NO_METHOD = :none

end
