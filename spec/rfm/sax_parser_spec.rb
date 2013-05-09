require 'data/sax_models'


describe Rfm::SaxParser::Handler do
	#subject {Rfm::SaxParser::Handler}
	Rfm.get_backend :rexml
	HANDLER = Rfm::SaxParser::RexmlHandler

	describe '#set_cursor' do
		subject {HANDLER.allocate} #new('local_testing/sax_parse.yml')}
		let(:input) { Rfm::SaxParser::Cursor.new({'elements'=>{'test'=>'True'}}, {:attribute=>'data'}, 'TEST') }
		before(:each) do
			subject.stack = []
		end
		
		it 'sends a cursor object to the stack' do
			subject.set_cursor(input)._obj.should == input._obj
			#subject.new(File.new('spec/data/resultset.xml'))['fmresultset']['datasource']['table'].should == 'Memo_'
		end
		
		
	end
	
	describe "Functional Parse" do
		it 'converts duplicate tags into appropriate hash or array' do
			r = HANDLER.build('spec/data/resultset_with_portals.xml', 'spec/data/sax_portals.yml').result
			#y r
			r['portals']['ProjectLineItemsSubItems_PLI'][2]['ProjectLineItemsSubItems_PLI::producetotal'].should == "1"
		end
	end
	
	
end # Handler	
	

	# 
	# 	describe '.decide_backend' do
	# 		it 'returns best backend that is currently loadable' do
	# 			(ActiveSupport::XmlMini.backend = subject.send(:decide_backend)).should_not be_nil
	# 		end
	# 	end
