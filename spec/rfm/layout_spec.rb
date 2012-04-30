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
		it "calls server.connect(state[:account_name], state[:password], action, params.merge(extra_params), options)" do
			server.should_receive(:connect) do |acnt, pass, actn, prms, opts|
				actn.should == '-find'
				prms[:prms].should == 'tst'
				opts[:opts].should == 'tst'
			end
			layout.send(:get_records, '-find', {:prms=>'tst'}, {:opts=>'tst'})
		end
		
		it "calls Rfm::Resultset.new(xml_response, self, include_portals)" do
			Rfm::Resultset.should_receive(:new) do |xml, slf, incprt|
				xml[0..4].should == '<?xml'
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
	
	describe "#find" do
	
		context "when passed FMP internal record id" do
			it "sends -find action & -recid & record id to #get_records" do
				layout.should_receive(:get_records) do |action, query, options|
					action.should == '-find'
					query['-recid'].should == '54321'
				end
				layout.find(54321)			
			end
		end
		
		context "when passed plain hash" do
			it "sends -find action & plain hash to #get_records" do
				layout.should_receive(:get_records) do |action, query, options|
					action.should == '-find'
					query[:memotext].should == 'val1'
				end
				layout.find(:memotext=>'val1', :memosubject=>'val2')			
			end		
		end		

		context "when passed plain hash with multiple value options for at least one field" do
			it "sends -findquery action & compound find criteria to #get_records" do
				layout.should_receive(:get_records) do |action, query, options|
					action.should == '-findquery'
					['(q0,q2);(q1,q2)','(q0,q1);(q0,q2)'].include?(query['-query']).should be_true
				end
				layout.find(:memotext=>['one','two'], :memosubject=>'three')
			end
		end
		
		context "when passed array of hashes" do
			it "sends -findquery action & compound find criteria to #get_records" do
				layout.should_receive(:get_records) do |action, query, options|
					action.should == '-findquery'
					['(q0,q2);(q1,q2);!(q3)','(q0,q1);(q0,q2);!(q3)'].include?(query['-query']).should be_true
				end
				layout.find([{:memotext=>['one','two'], :memosubject=>'three'}, {:omit=>true, :memotext=>'test'}])
			end
		end
	end
	
	describe "#modelize" do
		before(:all){layout.modelize}
		
		it "creates model subclassed from Rfm::Base" do
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