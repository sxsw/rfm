describe Rfm::SaxParser::Handler do
	#subject {Rfm::SaxParser::Handler}

	describe '#set_cursor' do
		subject {Rfm::SaxParser::OxFmpSax.allocate} #new('local_testing/sax_parse.yml')}
		let(:input) { Rfm::SaxParser::Cursor.new({'elements'=>{'test'=>'True'}}, {:attribute=>'data'}, 'TEST') }
		before(:each) do
			subject.stack = []
		end
		
		it 'sends a cursor object to the stack' do
			subject.set_cursor(input).obj.should == input.obj
			#subject.new(File.new('spec/data/resultset.xml'))['fmresultset']['datasource']['table'].should == 'Memo_'
		end
		
		
	end
	
	describe "Functional Parse" do
		it 'converts duplicate tags into appropriate hash or array' do
			r = Rfm::SaxParser::OxFmpSax.build('spec/data/resultset_with_portals.xml', 'spec/data/sax_portals.yml')
			r['relatedset']['ProjectLineItemsSubItems_PLI'][2]['ProjectLineItemsSubItems_PLI::producetotal'].should == "1"
		end
	end
	
	
end # Handler	
	
	# 	describe '.get_backend_from_hash' do
	# 		it 'loads OxSAX' do
	# 			subject.send(:get_backend_from_hash, :oxsax).should == ActiveSupport::XmlMini_OxSAX
	# 		end
	# 		it 'loads LibXML' do
	# 			subject.send(:get_backend_from_hash, :libxml).should == 'LibXML'
	# 		end
	# 		it 'loads LibXMLSAX' do
	# 			subject.send(:get_backend_from_hash, :libxmlsax).should == 'LibXMLSAX'
	# 		end
	# 		it 'loads NokogiriSAX' do
	# 			subject.send(:get_backend_from_hash, :nokogirisax).should == 'NokogiriSAX'
	# 		end
	# 		it 'loads Nokogiri' do
	# 			subject.send(:get_backend_from_hash, :nokogiri).should == 'Nokogiri'
	# 		end
	# 		it 'loads Hpricot' do
	# 			subject.send(:get_backend_from_hash, :hpricot).should == ActiveSupport::XmlMini_Hpricot
	# 		end
	# 		it 'loads REXML' do
	# 			subject.send(:get_backend_from_hash, :rexml).should == 'REXML'
	# 		end
	# 		it 'loads REXMLSAX' do
	# 			subject.send(:get_backend_from_hash, :rexmlsax).should == ActiveSupport::XmlMini_REXMLSAX
	# 		end
	# 	end
	# 
	# 	describe '.decide_backend' do
	# 		it 'returns best backend that is currently loadable' do
	# 			(ActiveSupport::XmlMini.backend = subject.send(:decide_backend)).should_not be_nil
	# 		end
	# 	end
