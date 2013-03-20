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
	@records = File.read('spec/data/resultset.xml')
	@layout = File.read('spec/data/layout.xml')
	Benchmark.bm do |b|
		[:oxsax, :libxml, :libxmlsax, :nokogirisax, :nokogiri, :hpricot, :rexml, :rexmlsax].each do |backend|
			Rfm.backend = backend
			b.report("#{Rfm::XmlParser.backend}\n") do
				50.times do
					Rfm::XmlParser.new(@records)
					Rfm::XmlParser.new(@layout)
				end
			end
		end
	end
end

desc "benchmark SaxParser engine"	
task :benchmark_sax do
	require 'benchmark'
	require 'yaml'
	@records = 'spec/data/resultset.xml'
	@layout = 'spec/data/layout.xml'
	Benchmark.bm do |b|
		[:OxFmpSax, :LibXmlSax, :NokogiriSax, :RexmlStream].each do |backend|
			b.report("#{backend}\n") do
				50.times do
					Rfm::SaxParser::Handler.build(@records, backend.to_s)
					Rfm::SaxParser::Handler.build(@layout, backend.to_s)
				end
			end
		end
	end
end

desc "Profile the sax parser"
task :sax_profile do
	require 'ruby-prof'
	# Profile the code
	result = RubyProf.profile do
		@records = 'spec/data/resultset.xml'
		Rfm::SaxParser::LibXmlSax.build(@records)
	end
	# Print a flat profile to text
	printer = RubyProf::FlatPrinter.new(result)
	printer.print(STDOUT, {})
	# Print a graph profile to text
	printer = RubyProf::GraphPrinter.new(result)
	printer.print(STDOUT, {})
end	

desc "run specs with all parsers"	
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
