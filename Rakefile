require 'rubygems'
require 'rake'
require './lib/rfm'

task :default => :spec

#require 'spec/rake/spectask'
#require 'rspec'
require 'rspec/core/rake_task'

# Manual
desc "Manually run rspec 2 - works but ugly"
task :spec do
	puts exec("rspec -O spec/spec.opts") #RUBYOPTS=W0  # silence ruby warnings.
end

#Spec::Rake::SpecTask
#RSpec::Core::RakeTask.new(:spec) # do |spec|
#   spec.libs << 'lib' << 'spec'
#   spec.spec_files = FileList['spec/**/*_spec.rb']
# end


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

desc "Print the version of Rfm"
task :version do
	puts Rfm::VERSION
end

desc "Print info about Rfm"
task :info do
	puts Rfm.info
end

desc "Benchmark loading & parsing XML data into Rfm classes"	
task :benchmark do
	require 'benchmark'
	require 'yaml'
	#load "spec/data/sax_models.rb"
	@records = File.read 'spec/data/resultset_large.xml'
	@template = 'lib/rfm/utilities/sax/fmresultset.yml'
	@base_class = Rfm::Resultset
	@layout = 'spec/data/layout.xml'
	Benchmark.bm do |b|
		[:rexml, :nokogiri, :libxml, :ox].each do |backend|
			b.report("#{backend}\n") do
				5.times do
					Rfm::SaxParser.parse(@records, @template, @base_class.new, backend)
					#Rfm::SaxParser::Handler.build(@layout, backend)
				end
			end
		end
	end
end

desc "Profile the sax parser"
task :profile_sax do
	# This turns on tail-call-optimization
	# See http://ephoz.posterous.com/ruby-and-recursion-whats-up-in-19
	if RUBY_VERSION[/1.9/]
		RubyVM::InstructionSequence.compile_option = {
		  :tailcall_optimization => true,
		  :trace_instruction => false
		}
	end
	require 'ruby-prof'
	# Profile the code
	@data = 'spec/data/resultset_large.xml'
	result = RubyProf.profile do
		# The parser will choose the best available backend.
		rr = Rfm::SaxParser.parse(@data, 'lib/rfm/utilities/sax/fmresultset.yml', Rfm::Resultset.new).result
		puts rr.class
		puts rr.size
	end
	# Print a flat profile to text
	printer = RubyProf::FlatPrinter.new(result)
	printer.print(STDOUT, {})
	# Print a graph profile to text
	printer = RubyProf::GraphPrinter.new(result)
	printer.print(STDOUT, {})
end

desc "Run test data thru the sax parser"
task :sample do
	@records = 'spec/data/resultset_large.xml'
	r= Rfm::SaxParser.parse(@records, 'lib/rfm/utilities/sax/fmresultset.yml', Rfm::Resultset.new).result
	puts r.to_yaml
	puts r.field_meta.to_yaml
end	

# Has not been updated to work with new parser in Rfm 3.0
# desc "run specs with all parser backends"	
# task :spec_multi do
# 	require 'benchmark'
# 	require 'yaml'
# 	@records = File.read('spec/data/resultset.xml')
# 	@layout = File.read('spec/data/layout.xml')
# 	Benchmark.bm do |b|
# 		[:oxsax, :libxml, :libxmlsax, :nokogirisax, :nokogiri, :hpricot, :rexml, :rexmlsax].each do |backend|
# 			#Rfm.backend = backend
# 			ENV['parser'] = backend.to_s
# 			b.report("#{backend.to_s.upcase}\n") do
# 				begin
# 					Rake::Task["spec"].execute
# 				rescue
# 					#puts $1
# 				end
# 			end
# 		end
# 	end
# end



desc "pre-commit, build gem, tag with version, push to git, push to rubygems.org"
task :release do
	gem_name = 'ginjo-rfm'
	shell = <<-EEOOFF
		echo "--- Pre-committing ---"
			git add .; git commit -m'Committing any lingering changes in prep for release of version #{Rfm::VERSION}'
		echo "--- Building gem ---" &&
			mkdir -p pkg &&
			output=`gem build #{gem_name}.gemspec` &&
			gemfile=`echo "$output" | awk '{ field = $NF }; END{ print field }'` &&
			echo $gemfile &&
			mv -f $gemfile pkg/ &&
		echo "--- Tagging with git ---" &&
			git tag -m'Releasing version #{Rfm::VERSION}' v#{Rfm::VERSION} &&
		echo "--- Pushing to git origin ---" &&
			git push origin &&
			git push origin --tags &&
		echo "--- Pushing to rubygems.org ---" &&
			gem push pkg/$gemfile
	EEOOFF
	#puts shell
	print exec(shell)
end
