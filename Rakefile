require 'rubygems'
require 'rake'
require './lib/rfm'

task :default => :spec

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
	@records = File.read('spec/data/resultset_large.xml')
	@layout = File.read('spec/data/layout.xml')
	Benchmark.bm do |b|
		[:oxsax, :libxml, :libxmlsax, :nokogirisax, :nokogiri, :hpricot, :rexml, :rexmlsax].each do |backend|
			Rfm.backend = backend
			b.report("#{Rfm::XmlParser.backend}\n") do
				5.times do
				# Rfm::XmlParser.new(@records)
				# Rfm::XmlParser.new(@layout)
					Rfm.load_data(@records)
				#	Rfm.load_data(@layout)
				end
			end
		end
	end
end

desc "benchmark SaxParser engine"	
task :benchmark_sax do
	require 'benchmark'
	require 'yaml'
	#load "spec/data/sax_models.rb"
	@records = 'spec/data/resultset_large.xml'
	@layout = 'spec/data/layout.xml'
	Benchmark.bm do |b|
		[:rexml, :nokogiri, :libxml, :ox].each do |backend|
			b.report("#{backend}\n") do
				5.times do
					Rfm::SaxParser.parse(@records, 'lib/rfm/sax/fmresultset.yml', Rfm::Resultset.new, backend)
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
	RubyVM::InstructionSequence.compile_option = {
	  :tailcall_optimization => true,
	  :trace_instruction => false
	}
	require 'ruby-prof'
	# Profile the code
	@records = 'spec/data/resultset_large.xml'
	result = RubyProf.profile do
		# The parser will choose the best available backend.
		Rfm::SaxParser.parse(@records, 'lib/rfm/sax/fmresultset.yml', Rfm::Resultset.new).result
	end
	# Print a flat profile to text
	printer = RubyProf::FlatPrinter.new(result)
	printer.print(STDOUT, {})
	# Print a graph profile to text
	printer = RubyProf::GraphPrinter.new(result)
	printer.print(STDOUT, {})
end

desc "Profile the sax parser"
task :sample do
	@records = 'spec/data/resultset_large.xml'
	r= Rfm::SaxParser.parse(@records, 'lib/rfm/sax/fmresultset.yml', Rfm::Resultset.new).result
	puts r.to_yaml
	puts r.field_meta.to_yaml
end	

desc "run specs with all parser backends"	
task :spec_multi do
	require 'benchmark'
	require 'yaml'
	@records = File.read('spec/data/resultset.xml')
	@layout = File.read('spec/data/layout.xml')
	Benchmark.bm do |b|
		[:oxsax, :libxml, :libxmlsax, :nokogirisax, :nokogiri, :hpricot, :rexml, :rexmlsax].each do |backend|
			#Rfm.backend = backend
			ENV['parser'] = backend.to_s
			b.report("#{backend.to_s.upcase}\n") do
				begin
					Rake::Task["spec"].execute
				rescue
					#puts $1
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
