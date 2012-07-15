require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "mongoid_nested_set"
  gem.homepage = "http://github.com/thinkwell/mongoid_nested_set"
  gem.license = "MIT"
  gem.summary = %Q{Nested set based tree implementation for Mongoid}
  gem.description = %Q{Fully featured tree implementation for Mongoid using the nested set model}
  gem.email = "bturner@bltweb.net"
  gem.authors = ["Brandon Turner"]
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :rcov do
  ENV['COVERAGE'] = 'yes'
  Rake::Task["spec"].execute
end

task :default => :spec

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "mongoid_nested_set #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
