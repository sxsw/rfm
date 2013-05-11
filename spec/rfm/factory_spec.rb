describe Rfm::Factory::ServerFactory do	
	subject {Rfm::Factory::ServerFactory.new}
	describe '#[]' do
		it "creates or retrieves server object, given host & options" do
			server = subject['test-host', :layout=>'test-layout-one']
			server.host_name.should == 'test-host'
			server.state[:layout].should == 'test-layout-one'
		end
	end
end # Rfm::Factory::ServerFactory


describe Rfm::Factory do

  subject        {Rfm::Factory}
  #let(:config)   {subject.instance_variable_get :@config}
  #let(:klass)    {Class.new{extend Rfm::Config; @config={:parent=>'Rfm::Config'}}}
  
  it "sets @config with :parent=>'Rfm::Config' upon loading" do
  	subject.config.should == {:parent=>'Rfm::Config'}
  end
  
  describe '.server' do
  	it "returns Rfm::Server instance, given name, filters, options hash" do
  		server = subject.server('test-host-one', :group1, :ssl=>'test')
  		server.host_name.should == 'test-host-one'
  		server.state[:host].should == 'test-host-one'
  		server.state[:database].should == 'db1'
  		server.state[:ssl].should == 'test'
  	end
  end
  
  describe '.db' do
  	it "returns Rfm::Database instance, given name, filters, options hash" do
  		database = subject.db('test-db-name', :group1, :account_name=>'my-name')
  		database.name.should == 'test-db-name'
  		database.account_name.should == 'my-name'
  	end
  end
  
  describe '.layout' do
  	it "returns Rfm::Layout instance, given name, filters, options hash" do
  		layout = subject.layout('test-layout-name', :group1, :account_name=>'my-name')
  		layout.name.should == 'test-layout-name'
  		layout.db.name.should == 'db1'
  		layout.db.account_name.should == 'my-name'
  	end
  end
  
end # Rfm::Factory

