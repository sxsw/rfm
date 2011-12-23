$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'yaml'
require 'rfm'
#require 'rfm/base'  # Use this to test if base.rb breaks anything, or if it's absence breaks anything.
require 'spec'
require 'spec/autorun'

puts Rfm.info_short

RFM_CONFIG = {
	:host=>'host1',
	:group1=>{
		:database=>'db1'
	},
	:group2=>{
		:database=>'db2'
	},
	:base_test=>{
		:database=>'testdb1',
		:layout=>'testlay1'
	}
}

Memo = Class.new(Rfm::Base){config :base_test}
SERVER = Memo.server
LAYOUT = Memo.layout.parent_layout
LAYOUT_XML = File.read('spec/data/layout.xml')
RESULTSET_XML = File.read('spec/data/resultset.xml')
RESULTSET_PORTALS_XML = File.read('spec/data/resultset_with_portals.xml')

Spec::Runner.configure do |config|	
	# 	config.before(:all) do
	# 		# 		SERVER = Rfm::Server.allocate
	# 		# 		SERVER.stub(:connect).and_return('something')
	# 		# 		Rfm::Server.stub(:new).and_return(SERVER)
	# 	end
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
