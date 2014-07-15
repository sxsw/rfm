### Run this from the command line with 'rspec -O spec/spec.opts'
### Run this with 'RUBYOPT=W0 -O spec/spec.opts' to silence warnings.

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'yaml'
require 'rfm'
#require 'rfm/base'  # Use this to test if base.rb breaks anything, or if it's absence breaks anything.
require 'rspec'

# Ruby 2.1.2 with activemodel 4.1.1 throws errors if I don't require minitest,
# but I don't think it's the reason ActiveModel Lint tests are failing.
# Turns out minitest 5 is the culprit of Lint test failures,
# but tons of rails-related gems require minitest >= 5.
# gem 'minitest' , '~>4.0.0'
# require 'minitest'
# See http://www.google.com/search?safe=off&client=safari&rls=en&q=rspec+%22undefined+method+%60assertions%27%22&oq=rspec+%22undefined+method+%60assertions%27%22&gs_l=serp.3...442200.450613.0.450958.16.12.3.1.1.0.125.795.11j1.12.0....0...1c.1j2.48.serp..1.15.755.mD-2_zLGUcw





#if ENV['parser']; Rfm.backend = ENV['parser'].to_sym; end
if ENV['parser']; Rfm::BACKEND = ENV['parser'].to_sym; end

puts Rfm.info
puts "RSpec: #{RSpec::Version::STRING}"
#puts "Ruby #{RUBY_VERSION}"

RFM_CONFIG = {
	:ignore_bad_data => true,
	:host=>'host1',
	:group1=>{
		:database=>'db1'
	},
	:group2=>{
		:database=>'db2'
	},
	:base_test=>{
		:database=>'testdb1',
		:layout=>'testlay1',
	}
}



Memo = TestModel = Class.new(Rfm::Base){config :base_test}
# SERVER = Memo.server
# LAYOUT = Memo.layout.parent_layout
LAYOUT_XML = File.read('spec/data/layout.xml')
RESULTSET_XML = File.read('spec/data/resultset.xml')
RESULTSET_PORTALS_XML = File.read('spec/data/resultset_with_portals.xml')

# Give each of these a body method that returns self.
[LAYOUT_XML, RESULTSET_XML, RESULTSET_PORTALS_XML].each{|c| class << c; def body; self; end; end}

#$VERBOSE=W0 # Silence ruby warnings.

RSpec.configure do |config|
	config.before(:each) do
		# See http://stackoverflow.com/questions/5591509/suppress-ruby-warnings-when-running-specs
		# Kernel.silence_warnings do
			#Memo = TestModel = Class.new(Rfm::Base){self.config :base_test}
			# NOTE the capitalization of these instance variables.
			@Layout = Memo.layout   #.parent_layout
			@Server = Memo.server

			#@Layout.stub(:load_layout).and_return(Rfm::SaxParser.parse(LAYOUT_XML, 'fmpxmllayout.yml', @Layout).result)
			
			Rfm::Connection.any_instance.stub(:connect) do |*args|
				#puts ["CONNECTION#connect args", args, self].flatten.join(', ')
				case args[0].to_s
				when /find/;
					#puts "RESULTSET"
					RESULTSET_XML
				when /view/
					#puts "LAYOUT"
					LAYOUT_XML
				end
			end
			
			# Enhanced workaround for #any_instance.stub {self}
			# See http://stackoverflow.com/questions/13893618/rspec-any-instance-return-self
			# See http://stackoverflow.com/questions/5938049/rspec-stubbing-return-the-parameter
			orig_new = Rfm::Connection.method(:new)
			Rfm::Connection.stub(:new) do |*args, &block|
			  orig_new.call(*args, &block).tap do |instance|
			    instance.stub(:connect) do |*args2|
						case instance.instance_variable_get(:@action)
						when /find/;
							#puts "RESULTSET"
							RESULTSET_XML
						when /view/
							#puts "LAYOUT"
							LAYOUT_XML
						end
					end
			  end
			end
			
			
		# end
	end
end

def rescue_from(&block)
  exception = nil
  begin
    yield
  rescue StandardError => e
    exception = e
  end
  exception
end
