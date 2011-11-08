require 'rfm/resultset'
#require 'yaml'

describe Rfm::Resultset do
  
  describe "#initialize" do
  
	  it "loads and parses xml response upon initialization" do
		  @server = Rfm::Server.allocate
		  def @server.state; {}; end
			@layout = Rfm::Layout.allocate
			@data = File.read("spec/data/resultset.xml")
			### records, result, field_meta, layout, portal
			Rfm::Record.instance_eval{def build_records(*args); args[1].instance_variable_set(:@build_records, args); end}  
			@resultset = Rfm::Resultset.new(@server, @data, @layout)
			
			@args = @resultset.instance_variable_get(:@build_records)
			@args[0].xpath('field')[0].inner_text.should eql('memotest3')
		end
		
	end	
end