describe Rfm::Base do

	Memo = Class.new(Rfm::Base){config :base_test}
	SERVER = Memo.server
	LAYOUT_XML = File.read('spec/data/layout.xml')
	RESULTSET_XML = File.read('spec/data/resultset.xml')
	
	before(:each) do
		LAYOUT_XML.stub(:body).and_return(LAYOUT_XML)
		RESULTSET_XML.stub(:body).and_return(RESULTSET_XML)

		SERVER.stub(:load_layout).and_return(LAYOUT_XML)
		SERVER.stub(:connect).and_return(RESULTSET_XML)
	end
	
	#Memo.field_controls
		
	describe 'Test stubbing' do
		it "server has stubbed methods for db connections" do
			m = Memo.new(:memotext=>'test1').save!
		end
	end

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
		  subject_test = Memo.new(:memosubject => 'test3')
			subject_test.server.should_receive(:connect) do |*args|
				args[2].should == '-new'
				args[3]['memosubject'].should == 'test3'
			end
			subject_test.save!
			subject_test[:memosubject].should == 'memotest4'	
		end
		
		it 'finds a record by id' do
			SERVER.should_receive(:connect) do |*args|
				args[2].should == '-find'
				args[3]['-recid'].should == '12345'
			end
			resultset = Memo.find(12345)
			resultset[0][:memosubject].should == 'memotest4'
		end
		
		it 'uses #update_attributes! to modify data'
		it 'searches for several records and loops thru to find this one'
		it 'destroys a record'
	end
  
  
end # Rfm::Base