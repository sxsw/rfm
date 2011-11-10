require 'rfm/resultset'
require 'yaml'

describe Rfm::Resultset do
  
  describe "#initialize" do
  	before do
		  @server = Rfm::Server.allocate
		  def @server.state; {}; end
			@layout = Rfm::Layout.allocate
			@data = File.read("spec/data/resultset.xml")
			### records, result, field_meta, layout, portal
			Rfm::Record.instance_eval{def build_records(*args); args[1].instance_variable_set(:@build_records, args); end}  
			@resultset = Rfm::Resultset.new(@server, @data, @layout)
			@args = @resultset.instance_variable_get(:@build_records)
  	end
  
	  it "loads and parses xml response upon initialization" do
			@args.should_not eql(nil)
		end
		
		it "sends field_meta to Record.build_records" do
			@args[2][:memokeymaster].class.should eql(Rfm::Metadata::Field)
		end
		
		it "sends layout to Record.build_records" do
			@args[3].class.should eql(Rfm::Layout)
		end
		
		it "sends records xml to Record.build_records" do
			@args[0].xpath('field')[0].inner_text.should eql('memotest3')
		end
		
	end	
end