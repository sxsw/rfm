# require 'data/sax_models'


describe Rfm::SaxParser::Handler do
	#subject {Rfm::SaxParser::Handler}
	HANDLER = Rfm::SaxParser::Handler.get_backend #:rexml
	before(:all) do; Rfm::SaxParser::TEMPLATE_PREFIX = '.'; end

	describe '#set_cursor' do
		# TODO: This seems really clumsy, clean it up.
		subject {HANDLER.allocate} #new('local_testing/sax_parse.yml')}
		#let(:input) { Rfm::SaxParser::Cursor.new({'elements'=>{'test'=>'True'}}, {:attribute=>'data'}, 'TEST', subject) }
		let(:input) { Rfm::SaxParser::Cursor.allocate.tap{|c| c.object = Object.new}}
		before(:each) do
			#Rfm::SaxParser.template_prefix = '.'
			# Rfm::SaxParser::TEMPLATE_PREFIX = '.'
			subject.stack = []
		end
		
		it 'sends a cursor object to the stack and returns object' do
			expect(subject.set_cursor(input).object).to eq(input.object)
			#subject.new(File.new('spec/data/resultset.xml'))['fmresultset']['datasource']['table'].should == 'Memo_'
		end
		
		it 'adds a cursor object to the stack' do
			5.times {subject.set_cursor(input)}
			expect(subject.stack.last).to eq(input)
			expect(subject.stack.size).to eq(5)
 		end		
		
	end
	
	describe "Functional Parse" do
		it 'converts duplicate tags into appropriate hash or array' do
			rr = HANDLER.build('spec/data/resultset_with_portals.xml', 'lib/rfm/utilities/sax/fmresultset.yml', Rfm::Resultset.new).result
			#y r
			expect(rr[0].portals['ProjectLineItemsSubItems_PLI'][2]['producetotal'].to_i).to eq(1)
		end
		
		it 'creates records with record_id and mod_id instance vars' do
			rr = HANDLER.build('spec/data/resultset_with_portals.xml', 'lib/rfm/utilities/sax/fmresultset.yml', Rfm::Resultset.new).result
			expect(rr[0].record_id).to eq("499")
			expect(rr[0].mod_id).to eq("86")
		end
		
		it 'creates total_count, founset_count, fetch_size on resultset' do
			rr = HANDLER.build('spec/data/resultset_with_portals.xml', 'lib/rfm/utilities/sax/fmresultset.yml', Rfm::Resultset.new).result
			expect(rr.total_count).to eq(3475)
			expect(rr.foundset_count).to eq(1)
			expect(rr.fetch_size).to eq(1)
		end
	end
	
	
end # Handler	
	

	# 
	# 	describe '.decide_backend' do
	# 		it 'returns best backend that is currently loadable' do
	# 			(ActiveSupport::XmlMini.backend = subject.send(:decide_backend)).should_not be_nil
	# 		end
	# 	end
