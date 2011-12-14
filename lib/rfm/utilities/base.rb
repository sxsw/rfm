module Rfm
	#
	# Adds ability to create Rfm::Base model classes that behave similar to ActiveRecord::Base models.
	# If you set your Rfm.config (or RFM_CONFIG) with your host, database, account, password, and
	# any other server/database options, you can provide your models with nothing more than a layout.
	#
	# 	class Person < Rfm::Base
	# 	  config :layout => 'mylayout'
	# 	end
	#
	# And similar to ActiveRecord, you can define callbacks, validations, attributes, and methods on your model.
	#
	#   class Account < Rfm::Base
	#     config :layout=>'account_xml'
	#     before_create :encrypt_password
	#     validates :email, :presence => true
	#     validates :username, :presence => true
	#     attr_accessor :password
	#   end
	#   
	# Then in your project, you can use these models just like ActiveRecord models.
	# The query syntax and options are still Rfm under the hood. Treat your model
	# classes like Rfm::Layout objects, with a few enhancements.
	#
	#   @account = Account.new :username => 'bill', :password => 'pass'
	#   @account.email = 'my@email.com'
	#   @account.save!
	#   
	#   @person = Person.find({:name => 'mike'}, :max_records => 50)[0]
	#   @person.update_attributes(:name => 'Michael', :title => "Senior Partner")
	#   @person.save
	# 
	# 
	#
	#
	# :nodoc: TODO: make sure all methods return something (a record?) if successful, otherwise nil or error
	# :nodoc: TODO: move rfm methods & patches from fetch_mail_with_ruby to this file
	#
	# TODO: Are these really needed here?
	require 'rfm/record'
	require 'rfm/layout'
  
  class Layout
  	attr_accessor :model
  end
        
  class Record
  	class << self
	  	alias_method :new_orig, :new
	  	def new(record={}, resultset_obj=[], field_meta='', layout_obj=nil, portal=nil) # record, result, field_meta, layout, portal
	  		#layout_obj = layout rescue layout_obj
	      model = layout_obj.model || Record rescue Record
	      model.new_orig(record, resultset_obj, field_meta, layout_obj, portal)
	    end
    end # class << self
  end # class Record
	
	
  class Base <  Rfm::Record  #Hash
    extend Config
    config :parent=>'Rfm::Config'
    
    begin
    	require 'active_model'
      include ActiveModel::Validations
      extend ActiveModel::Callbacks
      define_model_callbacks(:create, :update, :destroy)
    rescue LoadError, StandardError
    	def run_callbacks(*args)
    		yield
    	end
    end
    
		alias_method :initialize_orig, :initialize
		def initialize(record, resultset_obj, field_meta, layout_obj, portal)
			if record and resultset_obj == [] and !record.has_key? 'field'   #!record.respond_to? :xpath
				@mods = Rfm::CaseInsensitiveHash.new
				@layout = layout_obj
				@resultset = Resultset.allocate
        # loop thru each layout field, creating hash keys with nil values
        layout_obj.field_names.each do |field|
          field_name = field.to_s
          self[field_name] = nil
        end
        self.update_attributes(record) unless record == {}
        self.merge!(@mods) unless @mods == {}
        @loaded = true
      else
      	initialize_orig(record, resultset_obj, field_meta, layout_obj, portal)
      end
			yield(self) if block_given?
		end
    
    
		
		class << self
		
	    # Access layout functions from base model
	  	def_delegators :layout, :db, :server, :field_controls, :field_names, :value_lists, :total_count,
	  									:query, :all, :delete
		
			def inherited(model)
				(Rfm::Factory.models << model).uniq unless Rfm::Factory.models.include? model
				model.config :parent=>'Rfm::Base'
			end
			
			# Access/create the layout object associated with this model
	  	def layout
	  		return @layout if @layout
	  		@layout = Rfm::Factory.layout(config_all)
				@layout.model = self
				@layout
	  	end
	  
		  # Convenience methods
		  alias_method :fm, :layout
			
			# Just like Layout#find, but searching by record_id will return a record, not a resultset.
	  	def find(*args)
	  	  r = layout.find(*args)
	  	  if args[0].class != Hash and r.size == 1
	  	    r[0]
		    else
		      r
	      end
	    rescue Rfm::Error::RecordMissingError
	      nil
	  	end

			# Layout#any, returns single record, not resultset
	  	def any(*args)
	  	  layout.any(*args)[0]
	  	end

			# New record, save, (with callbacks & validations if ActiveModel is loaded)
	  	def create(*args)
	  	  new(*args).send :create
	  	end
	  		  
	    # Using this method will skip callbacks. Use instance method +#update+ instead
		  def edit(*args)
		    layout.edit(*args)[0]
	    end
	    
		end # class << self
		
		
		
		
		# Is this a newly created record, not saved yet?					
  	def new_record?
  		return true if self.record_id.blank?
  	end

		# Reload record from database
		# TODO: handle error when record has been deleted
		def reload(force=false)
	    if (@mods.empty? or force) and record_id
	      self.replace self.class.find(self.record_id)
      end
    end
    
    # Mass update of record attributes, without saving.
    # TODO: return error or nil if input hash contains no recognizable keys.
    def update_attributes(new_attr)
      # creates new special hash
      input_hash = Rfm::CaseInsensitiveHash.new
      # populate new hash with input, coercing keys to strings
      new_attr.each{|k,v| input_hash.merge! k.to_s=>v}
      # loop thru each layout field, adding data to @mods
      self.class.field_controls.keys.each do |field| 
        field_name = field.to_s
        if input_hash.has_key?(field_name)
          @mods.merge! field_name=>(input_hash[field_name] || '')
        end
      end
      # loop thru each input key-value,
      # creating new attribute if key doesn't exist in model.
      input_hash.each do |k,v| 
        if !self.class.field_controls.keys.include?(k) and self.respond_to?(k)
          self.instance_variable_set("@#{k}", v)
        end
      end            
      self.merge!(@mods) unless @mods == {}
    end
    
    # Mass update of record attributes, with saving.
    def update_attributes!(new_attr)
      self.update_attributes(new_attr)
      self.save!
    end
    
    # Save record modifications to database (with callbacks & validations). If record cannot be saved will raise error.
    def save!
      #return unless @mods.size > 0
      raise "Record Invalid" unless valid?
      if @record_id
        self.update
      else
        self.create
      end
    end
    
	  # Same as save!, but will not raise error.
    def save
      save!
    rescue
      self.errors[:base] << $!
      return nil
    end
	  
		# Just like Layout#save_if_not_modified, but with callbacks & validations.
    def save_if_not_modified
      update(@mod_id) if @mods.size > 0
    end    
    
    # Delete record from database, with callbacks & validations.
  	def destroy
  	  return unless record_id
  	  run_callbacks :destroy do
  	    self.class.delete(record_id)
  	    @mods.clear
	    end
	    self.freeze
  	  #self
	  end
    
	
  protected # class Base
  
  	def self.create_from_new(*args)
  	  layout.create(*args)[0]
  	end
  
    # shunt for callbacks when not using ActiveModel
    def callback_deadend (*args)
      yield  #(*args)
    end
    
    def create
      #return unless @mods.size > 0
      run_callbacks :create do
        return unless @mods.size > 0
  	    merge_rfm_result self.class.create_from_new(@mods)
  	  end
  	  self
  	end
  	
    def update(mod_id=nil)
      #return unless @mods.size > 0 and record_id
      return false unless record_id
  	  run_callbacks :update do
  	    return unless @mods.size > 0
  	    unless mod_id
  	      # regular save
  	      merge_rfm_result self.class.send :edit, record_id, @mods
	      else
	        # save_if_not_modified
	        merge_rfm_result self.class.send :edit, record_id, @mods, :modification_id=>mod_id
        end
  	  end
  	  self
  	end
  	
  	def merge_rfm_result(result_record)
      return unless @mods.size > 0
      @record_id ||= result_record.record_id
      self.merge! result_record
      @mods.clear
      self || {}
    end
    
  end ### class Base

end # module Rfm



