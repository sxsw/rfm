describe Rfm::Layout do
  let(:server)   {(Rfm::Server).allocate}
  let(:database) {(Rfm::Database).allocate}
  #let(:data)     {File.read("spec/data/resultset.xml")}
  #let(:meta)     {File.read("spec/data/layout.xml")}
  let(:name)     {'test_layout'}
  let(:layout)   {Rfm::Layout.new(name, database)}
	before(:each) do
		server.stub!(:connect).and_return(RESULTSET_XML)
		server.stub!(:load_layout).and_return(LAYOUT_XML)
		server.stub!(:state).and_return({})
		database.stub!(:server).and_return(server)
		#data.stub!(:body).and_return(RESULTSET_XML)
		#meta.stub!(:body).and_return(LAYOUT_XML)
	end
		
	describe "#initialze" do
		it "should load instance variables" do
			layout.name.should == name
			layout.db.should == database
			layout.instance_variable_get(:@loaded).should == false
			layout.instance_variable_get(:@field_controls).class.should == Rfm::CaseInsensitiveHash
			layout.instance_variable_get(:@value_lists).class.should == Rfm::CaseInsensitiveHash		
		end
	end # initialize
	
	describe "#get_records" do
		it "calls db.server.connect(db.account_name, db.password, action, params.merge(extra_params), options)" do
			server.should_receive(:connect) do |acnt, pass, actn, prms, opts|
				actn.should == '-find'
				prms[:prms].should == 'tst'
				opts[:opts].should == 'tst'
			end
			layout.send(:get_records, '-find', {:prms=>'tst'}, {:opts=>'tst'})
		end
		
		it "calls Rfm::Resultset.new(db.server, xml_response, self, include_portals)" do
			Rfm::Resultset.should_receive(:new) do |srv, rsp, slf, incprt|
				srv.class.should == Rfm::Server
				slf.should == layout
				incprt.should == nil
			end
			layout.send(:get_records, '-find', {:prms=>'tst'}, {:opts=>'tst'})
		end
		
		it "returns instance of Resultset" do
			layout.send(:get_records, '-find', {:prms=>'tst'}, {:opts=>'tst'}).class.should == Rfm::Resultset
		end
	end #get_records
	
	describe "#load" do
		it "sets @field_controls and @value_lists from xml" do
			layout.send(:load)
			layout.instance_variable_get(:@field_controls).has_key?('stayid').should be_true
			layout.instance_variable_get(:@value_lists).has_key?('employee unique id').should be_true
		end
	end
	
	describe "#any" do
		it "returns resultset containing instance of Rfm::Record" do
			layout.send(:any)[0].class.should == Rfm::Record
		end
	end
	
	describe "#modelize" do
		before(:all){layout.modelize}
		
		it "creates model subclassed from Rfm::Base" do
			y layout
			layout.models[0].superclass.should == Rfm::Base
		end
		
		it "stores model in layout@model as constant based on layout name" do
			layout.models[0].should == TestLayout
		end
		
		it "sets model@layout with layout object" do
			layout.models[0].layout.should == layout
		end
	end


end # Rfm::Resultset