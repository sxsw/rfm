require 'rubygems'
require 'rake'
require './lib/rfm'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "ginjo-rfm"
    gem.summary = "Ruby to Filemaker adapter"
    gem.description = "Rfm brings your FileMaker data to Ruby. Now your Ruby scripts and Rails applications can talk directly to your FileMaker server."
    gem.email = "http://groups.google.com/group/rfmcommunity"
    gem.homepage = "http://sixfriedrice.com/wp/products/rfm/"
    gem.authors = ["Geoff Coffey", "Mufaddal Khumri", "Atsushi Matsuo", "Larry Sprock", "Bill Richardson"]
    gem.files = FileList['lib/**/*']
    gem.add_dependency('activesupport')
    gem.add_dependency('activemodel')
    gem.add_development_dependency('jeweler')
    gem.add_development_dependency('rake')
    gem.add_development_dependency('rdoc')
    gem.add_development_dependency('rspec', '~>1.3.0')
    gem.rdoc_options = [ "--line-numbers", "--main", "README.rdoc" ]
    gem.version = Rfm::VERSION
  end
  #Jeweler::GemcutterTasks.new
  Jeweler::RubygemsDotOrgTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  elsif (Rfm::VERSION rescue nil)
  	version = Rfm::VERSION
  elsif File.exist?('VERSION')
    version = File.read('VERSION')
  else
  	version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rfm #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end


# Rspec 2 beginnings
# require 'rspec/core/rake_task'
# RSpec::Core::RakeTask.new(:spec) do |spec|
#   spec.libs << 'lib' << 'spec'
#   spec.spec_files = FileList['spec/**/*_spec.rb']
# end
# 
# RSpec::Core::RakeTask.new(:rcov) do |spec|
#   spec.libs << 'lib' << 'spec'
#   spec.pattern = 'spec/**/*_spec.rb'
#   spec.rcov = true
# end

