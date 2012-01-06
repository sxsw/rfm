require 'rubygems'
require 'rake'
require './lib/rfm'

# begin
#   require 'jeweler'
#   Jeweler::Tasks.new do |gem|
#     gem.name = "ginjo-rfm"
#     gem.summary = "Ruby to Filemaker adapter"
#     gem.description = "Rfm brings your FileMaker data to Ruby. Now your Ruby scripts and Rails applications can talk directly to your FileMaker server."
#     gem.email = "http://groups.google.com/group/rfmcommunity"
#     gem.homepage = "http://sixfriedrice.com/wp/products/rfm/"
#     gem.authors = ["Geoff Coffey", "Mufaddal Khumri", "Atsushi Matsuo", "Larry Sprock", "Bill Richardson"]
#     gem.files = FileList['lib/**/*']
#     gem.add_dependency('activesupport', '>= 2.3.5')
#     gem.add_development_dependency('jeweler')
#     gem.add_development_dependency('rake')
#     gem.add_development_dependency('rdoc')
#     gem.add_development_dependency('rspec', '~>1.3.0')
#			gem.add_development_dependency('diff-lcs', '>= 0')
#     gem.add_development_dependency('yard')
#     gem.add_development_dependency('hpricot')
#     gem.add_development_dependency('libxml-ruby')
#     gem.add_development_dependency('nokogiri')
#     gem.add_development_dependency('ox')
#     gem.add_development_dependency('activemodel')
#     gem.rdoc_options = [ "--line-numbers", "--main", "README.md" ]
#     gem.version = Rfm::VERSION
#   end
#   Jeweler::RubygemsDotOrgTasks.new
# rescue LoadError
#   puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
# end

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

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
	version = Rfm::VERSION
	rdoc.main = 'README.md'
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Rfm #{version}"
  rdoc.rdoc_files.include('lib/**/*.rb', 'README.md', 'CHANGELOG.md', 'VERSION', 'LICENSE')
end

require 'yard'
require 'rdoc'
YARD::Rake::YardocTask.new do |t|
	# See http://rubydoc.info/docs/yard/file/docs/GettingStarted.md
	# See 'yardoc --help'
  t.files   = ['lib/**/*.rb', 'README.md', 'LICENSE', 'VERSION', 'CHANGELOG.md']   # optional
  t.options = ['-oydoc', '--no-cache', '-mrdoc', '--no-private'] # optional
end


task :default => :spec

desc "Print the version of Rfm"
task :version do
	puts Rfm::VERSION
end

desc "Print info about Rfm"
task :info do
	puts Rfm.info
end


desc "benchmark XmlMini with available parsers"	
task :benchmark do
	require 'benchmark'
	require 'yaml'
	@records = File.read('spec/data/resultset.xml')
	@layout = File.read('spec/data/layout.xml')
	Benchmark.bm do |b|
		[:oxsax, :libxml, :libxmlsax, :nokogirisax, :nokogiri, :hpricot, :rexml, :rexmlsax].each do |backend|
			Rfm.backend = backend
			b.report("#{Rfm::XmlParser.backend}\n") do
				50.times do
					Rfm::XmlParser.new(@records)
					Rfm::XmlParser.new(@layout)
					#Thread.new {Rake::Task["spec"].execute}
					#`rake spec > /dev/null`
				end
			end
		end
	end
end



desc "pre-commit, build gem, tag with version, push to git, push to rubygems.org"
task :release do
	gem_name = 'ginjo-rfm'
	shell = <<-EEOOFF
		echo "--- Pre-committing ---"
			git add .; git commit -m'Committing any lingering changes in prep for release of version #{Rfm::VERSION}'
		echo "--- Building Gem ---" &&
			mkdir -p pkg &&
			output=`gem build #{gem_name}.gemspec` &&
			gemfile=`echo "$output" | awk '{ field = $NF }; END{ print field }'` &&
			echo $gemfile &&
			mv -f $gemfile pkg/ &&
		echo "--- Tagging With Git ---" &&
			git tag -m'Releasing version #{Rfm::VERSION}' v#{Rfm::VERSION} &&
		echo "--- Pushing to Git ---" &&
			git push origin &&
			git push origin --tags &&
		echo "--- Pushing to Rubygems.org ---" &&
			gem push pkg/$gemfile
	EEOOFF
	puts shell
	print exec(shell)
end
