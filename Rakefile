require "bundler/gem_tasks"

task :spec do
  specs = Dir.glob("spec/**/*_spec.rb")
  system("rspec -c -f p #{specs.join ' '}")
end
