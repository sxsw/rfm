###    RfmHelper module   ###
# Adds ability to create RFM model classes that behave similar to ActiveRecord #
# Example:
# class Person < RfmHelper::Base
#   config :host, 'my.server.com'
#   config :account_name=>'special', :password=>'somepass'
#   def full_name
#     "#{firstname} #{lastname}"
#   end
# end
#
# p = Person.find(:firstname=>'bill')[0]
# p.first_name = 'bob'
# p.save
# r = Person.new(:firstname=>'ted')
# r.lastname = 'johnson'
# r.save
#
# Remember that RFM & Nokogiri requires a modern libxml2, libxslt, and libiconv
# See Nokogiri web site for fixing install problems with Nokogiri
# If all of these libs are up to date, and noko still won't work,
# delete noko gem, and reinstall.
# This should work with latest noko.
#
#
# Example model definitions:
# class Person < Rfm::Base
#   config :account_name=>'someaccount', :host=>'http://some.domain.com', :database=>'MyFmDatabase', :password=>'mypass'
# end
# 
# class Memo < Rfm::Base
#   config :layout, 'memo_xml'
#   field_controls # pre-loads field controls from database
#   def test
#     "Memosubject: #{memosubject}; Memotext: #{memotext}"
#   end
# end
# 
# class ActionItem < RfmHelper::Base
#   config :layout, 'action_items_xml'
#   field_controls
#   def rec
#     "#{record_id} #{recordid}"
#   end
# end
#
#
# TODO: make sure all methods return something (a record?) if successful, otherwise nil or error
# TODO: move rfm methods & patches from fetch_mail_with_ruby to this file


module Rfm
	
	# TODO: Are these really needed here?
	require 'rfm/record'
	require 'rfm/layout'



  ### Rfm direct class mods ###
  
  class Layout
  	attr_accessor :model
  end
        
  class Record
  	
  	class << self
	  	alias_method :new_orig, :new
	  	def new(record={}, resultset_obj=[], field_meta='', layout_obj=nil, portal=nil) # record, result, field_meta, layout, portal
	  		layout_obj = layout rescue layout_obj
	      model = layout_obj.model || Record rescue Record
	      model.new_orig(record, resultset_obj, field_meta, layout_obj, portal)
	    end
    end
    
  end # class Record



  ### Rfm::Base ###

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
			if resultset_obj == [] and  !record.has_key? 'field'   #!record.respond_to? :xpath
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
    
    
		
		### Class Methods ###

		class << self
			
	  	def layout(*args)
	  		return @layout if (@layout and args==[])
	  		opt = args.last.is_a?(Hash) ? args.pop : {}
	  	  layout_name = (args[0].class == String ? args[0] : nil)
	      conf = config_merge_args(config_core.dup, opt)
				conf.merge!(:layout=>layout_name) if layout_name
				layout = Rfm::Factory.layout(conf)
				#layout.instance_variable_set(:@model, self.to_s)
				layout.model = self
				@layout = layout
	  	end
	  	
	    # Access layout functions from base model
	  	def_delegators :layout, :db, :server, :field_controls, :field_names, :value_lists
	  
		  # Convenience methods
		  alias_method :fm, :layout
		
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
		
	  	def any(*args)
	  	  layout.any(*args)[0]
	  	end
		
	  	def create(*args)
	  	  new(*args).send :create
	  	end
	  	
	  	def create_from_instance(*args)
	  	  layout.create(*args)[0]
	  	end
	  
	    # Using this method will skip callbacks. Use instance 'update' instead
		  def edit(*args)
		    layout.edit(*args)[0]
	    end
	  
	    # Using this method will skip callbacks. Use instance 'destroy' instead
	    def delete(*args)
	      layout.delete(*args)
	    end
	    
	    def query(*args)
	      layout.query(*args)
	    end

		end # class << self
		
		
		
		### Instance Methods ###
						
  	def new_record?
  		return true if self.record_id.blank?
  	end

		# TODO: handle error when record has been deleted
		def reload(force=false)
	    if (@mods.empty? or force) and record_id
	      self.replace self.class.find(self.record_id)
      end
    end
    
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
    
    def update_attributes!(new_attr)
      self.update_attributes(new_attr)
      self.save!
    end
    
    def save!
      #return unless @mods.size > 0
      raise "Record Invalid" unless valid?
      if @record_id
        self.update
      else
        self.create
      end
    end
    
  	def destroy
  	  return unless record_id
  	  run_callbacks :destroy do
  	    self.class.delete(record_id)
  	    @mods.clear
	    end
  	  self
	  end
	  
    def save
      save!
    rescue
      self.errors[:base] << $!
      return nil
    end

    def save_if_not_modified
      update(@mod_id) if @mods.size > 0
    end    
    
    
    
	
  protected # class Base
  
    # shunt for callbacks pre rails 3
    def callback_deadend (*args)
      yield
    end
    
    
    def create
      #return unless @mods.size > 0
      run_callbacks :create do
        return unless @mods.size > 0
  	    merge_rfm_result self.class.create_from_instance(@mods)
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
  	      merge_rfm_result self.class.edit(record_id, @mods)
	      else
	        # save_if_not_modified
	        merge_rfm_result self.class.edit(record_id, @mods, :modification_id=>mod_id)
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



