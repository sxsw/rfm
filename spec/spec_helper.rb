$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'yaml'
require 'rfm'
#require 'rfm/base'  # Use this to test if base.rb breaks anything, or if it's absence breaks anything.
# require 'spec'
# require 'spec/autorun'
require 'rspec'

if ENV['parser']; Rfm.backend = ENV['parser'].to_sym; end

puts Rfm.info_short
puts "RSpec #{RSpec::Version::STRING}"

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

RSpec.configure do |config|
	config.before(:each) do
		Kernel.silence_warnings do
			#Memo = TestModel = Class.new(Rfm::Base){self.config :base_test}
			# NOTE the capitalization of these instance variables.
			@Layout = Memo.layout   #.parent_layout
			@Server = Memo.server

			@Server.stub(:load_layout).and_return(LAYOUT_XML)
			@Server.stub(:connect).and_return(RESULTSET_XML)
			@Layout.stub(:load_layout).and_return(Rfm::SaxParser.parse(LAYOUT_XML, 'fmpxmllayout.yml', @Layout))
		end
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
