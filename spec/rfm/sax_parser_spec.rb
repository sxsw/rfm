# require 'data/sax_models'


describe Rfm::SaxParser::Handler do
	#subject {Rfm::SaxParser::Handler}
	#Rfm.get_backend :rexml
	HANDLER = Rfm::SaxParser::Handler.get_backend :rexml

	describe '#set_cursor' do
		subject {HANDLER.allocate} #new('local_testing/sax_parse.yml')}
		let(:input) { Rfm::SaxParser::Cursor.new({'elements'=>{'test'=>'True'}}, {:attribute=>'data'}, 'TEST', subject) }
		before(:each) do
			#Rfm::SaxParser.template_prefix = '.'
			Rfm::SaxParser::TEMPLATE_PREFIX = '.'
			subject.stack = []
		end
		
		it 'sends a cursor object to the stack and returns object' do
			subject.set_cursor(input).object.should == input.object
			#subject.new(File.new('spec/data/resultset.xml'))['fmresultset']['datasource']['table'].should == 'Memo_'
		end
		
		
	end
	
	describe "Functional Parse" do
		it 'converts duplicate tags into appropriate hash or array' do
			rr = HANDLER.build('spec/data/resultset_with_portals.xml', 'lib/rfm/utilities/sax/fmresultset.yml', Rfm::Resultset.new).result
			#y r
			rr[0].portals['ProjectLineItemsSubItems_PLI'][2]['producetotal'].to_i.should == 1
		end
	end
	
	
end # Handler	
	

	# 
	# 	describe '.decide_backend' do
	# 		it 'returns best backend that is currently loadable' do
	# 			(ActiveSupport::XmlMini.backend = subject.send(:decide_backend)).should_not be_nil
	# 		end
	# 	end
