describe Rfm::Config do

  subject        {Rfm::Config}
  let(:config)   {subject.instance_variable_get :@config}
  let(:klass)    {Class.new{extend Rfm::Config; @config={:parent=>'Rfm::Config'}}}
  
	describe "on module load" do
		it "loads RFM_CONFIG into @config" do
			config.should == RFM_CONFIG
		end
	end  
	
	describe "#config" do
		before(:each){klass.config :group1, :layout=>'lay1'}
	
		it "sets @config with arguments & options" do
			klass.instance_variable_get(:@config).should == {:use=>:group1, :layout=>'lay1', :parent=>'Rfm::Config'}
		end
		
		it "returns @config" do
			klass.config.should == klass.instance_variable_get(:@config)
		end
	end
	
	describe "#get_config" do
		context "with no arguments" do
			it "returns upstream config" do
				klass.get_config.should == {:host=>'host1', :parent=>'Rfm::Config', :strings=>[]}
			end
		end
		
		context "with preset filters but no arguments" do
			it "returns upstream config, merged with filtered groups" do
				klass.config :group1
				klass.get_config.should == {:host=>'host1', :parent=>'Rfm::Config', :strings=>[], :database=>'db1', :use=>[:group1]}
			end
		end
		
		context "with array of symbols and hash of options" do
			it "returns upstream config, merged with filtered groups, merged with options, ignoring preset filters" do
				klass.config :group1
				klass.get_config(:group2, :ssl=>true).should == {:host=>'host1', :parent=>'Rfm::Config', :strings=>[], :database=>'db2', :ssl=>true, :use=>[:group1]}
			end
			
			it "returns config including :strings parameter, if passed array of strings as first n arguments" do
				klass.config :group1
				klass.get_config('test-string-one', 'test-string-two', :group2, :ssl=>true)[:strings][1].should == 'test-string-two'
			end
			
		end
	end

end # Rfm::Config