describe Rfm::Base do

	before(:all) do
		@layout_xml = File.read('spec/data/layout.xml')
		@layout_xml.stub!(:body).and_return(@layout_xml)
		@resultset_xml = File.read('spec/data/resultset.xml')
		@resultset_xml.stub!(:body).and_return(@resultset_xml)
		class Memo < Rfm::Base
			config :base_test
		end
		@server = Memo.server
		@server.stub!(:load_layout).and_return(@layout_xml)
		@server.stub!(:connect).and_return(@resultset_xml)
	end
	#subject {Memo}

	describe '.inherited' do
		it("adds new model class to Rfm::Factory@models"){Rfm::Factory.models.include?(Memo).should be_true}
		it("sets model @config with :parent and other config options") do
			Memo.get_config[:parent].should == 'Rfm::Base'
			Memo.get_config[:layout].should == 'testlay1'
		end
	end
	
	describe '.layout' do
		it("retrieves or creates layout object"){Memo.layout.name.should == 'testlay1'}
		it("layout object is a SubLayout"){Memo.layout.is_a?(Rfm::Layout::SubLayout)}
	end
	
	# describe '.find'
	# 
	# describe '.create_from_instance'
	# 
	# describe '#initialize'
	# 
	# describe '#new_record?'
	# 
	# describe '#reload'
	# 
	# describe '#update_attributes'
	# 
	# describe '#update_attributes!'
	# 
	# describe '#save!'
	# 
	# describe '#save'
	# 
	# describe '#destroy'
	# 
	# describe '#save_if_not_modified'
	# 
	# describe '#callback_deadend'
	# 
	# describe '#create'
	# 
	# describe '#update'
	# 
	# describe '#merge_rfm_result'
	

	describe 'Functional Tests -' do
		describe 'Basic CRUD manoevers -' do
			# 	before(:each) do
			# 		subject.server.stub!(:load_layout).and_return(@layout_xml)
			# 		subject.server.stub!(:connect).and_return(@resultset_xml)
			# 	end
			
			it "sucks" do
				puts "Memo.layout: #{Memo.layout.class} #{Memo.layout.object_id}"
			end
			
			it 'creates a new record with data' do
				subject_test = Memo.new(:memotext=>'test1')
				subject_test.memotext.should == 'test1'
				subject_test.class.should == Memo			
			end
			
			it 'adds more data to the record' do
				subject_test = Memo.new
				subject_test.memosubject = 'test2'
				subject_test.instance_variable_get(:@mods).size.should > 0
			end
			
			it 'saves the record' do
				subject_test = Memo.new
			  subject_test.memosubject = 'test3'
				# subject.server.should_receive(:connect).with(*args).and_return(@resultset_xml) do
				# 	args[2].should == '-save'
				# end
				subject_test.save![:memosubject].should == 'memotest4'	
			end
			
			it 'finds a record by id' do
				subject_test = Memo.find(12345)
				subject_test.class.should == Memo
			end
			it 'uses #update_attributes! to modify data'
			it 'searches for several records and loops thru to find this one'
			it 'destroys a record'
		end
	end
  
  
end # Rfm::Base