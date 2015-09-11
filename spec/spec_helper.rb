### Run this from the command line with 'rspec -O spec/spec.opts'
### Run this with 'RUBYOPT=W0 -O spec/spec.opts' to silence warnings.

### To run a single rspec test:
### rake spec SPEC=spec/rfm/sax_parser_spec.rb SPEC_OPTS="-e \"loads each portal array with instances of Rfm::Record\""



$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'yaml'
require 'rfm'
#require 'rfm/base'  # Use this to test if base.rb breaks anything, or if it's absence breaks anything.
require 'rspec'
require 'active_model/lint'

#if ENV['parser']; Rfm.backend = ENV['parser'].to_sym; end
Rfm::BACKEND = if ENV['parser'];
  ENV['parser'].to_sym
else
  :rexml
end

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
[LAYOUT_XML, RESULTSET_XML, RESULTSET_PORTALS_XML].each do |c|
  class << c
    def body
      self
    end
  end
end

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
      
      allow_any_instance_of(Rfm::Connection).to receive(:connect) do |instance, *args|
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
      allow(Rfm::Connection).to receive(:new) do |*args, &block|
        orig_new.call(*args, &block).tap do |instance|
          allow(instance).to receive(:connect) do |*args2|
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

  config.mock_with :rspec do |mocks|
    # In RSpec 3, `any_instance` implementation blocks will be yielded the receiving
    # instance as the first block argument to allow the implementation block to use
    # the state of the receiver.
    # In RSpec 2.99, to maintain compatibility with RSpec 3 you need to either set
    # this config option to `false` OR set this to `true` and update your
    # `any_instance` implementation blocks to account for the first block argument
    # being the receiving instance.
    mocks.yield_receiver_to_any_instance_implementation_blocks = true
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
