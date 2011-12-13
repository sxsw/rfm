# This data must load before Rfm.
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

# Begin loading Rfm
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rfm'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
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
