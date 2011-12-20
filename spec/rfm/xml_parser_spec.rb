describe Rfm::XmlParser do
subject {Rfm::XmlParser}

	describe '.new' do
		it 'parses XML string or file' do
			subject.new(File.new('spec/data/resultset.xml'))['fmresultset']['datasource']['table'].should == 'Memo_'
		end
	end
	
	describe '.get_backend_from_hash' do
		it 'returns backend usable by XmlMini, given input symbol' do
			subject.send(:get_backend_from_hash, :libxml).should == 'LibXML'
			subject.send(:get_backend_from_hash, :libxmlsax).should == 'LibXMLSAX'
			subject.send(:get_backend_from_hash, :nokogirisax).should == 'NokogiriSAX'
			subject.send(:get_backend_from_hash, :nokogiri).should == 'Nokogiri'
			subject.send(:get_backend_from_hash, :hpricot).should == ActiveSupport::XmlMini_Hpricot
		end
	end

	describe '.decide_backend' do
		it 'returns best backend that is currently loadable' do
			subject.send(:decide_backend).should == 'LibXML'
		end
	end

end