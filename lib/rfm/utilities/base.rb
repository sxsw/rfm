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
	

  ### RfmHelper::Base (base model for new records) ###
  class Base <  Rfm::Record  #Hash
    #attr_accessor :record_id unless defined? record_id
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
      #alias_method(:run_callbacks, :callback_deadend)
    end
    
    # --- #
		
		class << self
		
			# 	  	# Returns new RFM server object
			# 	  	def server(*args)
			# 	  		return @server if (@server and args==[])
			# 	      conf = config_merge_args(config_core.dup, args)
			# 	  	  @server = Rfm::Server.new(conf)
			# 		  end
			# 	  
			# 		  # Returns new RFM db object
			# 		  def db(*args)
			# 		  	return @db if (@db and args==[])
			# 	      conf = config_merge_args(config_core.dup, args)
			# 				# 	  	  server  = Rfm::Server.new(conf)
			# 				# 	  	  db      = conf[:database]
			# 				# 	  	  @db = server[db]
			# 				@db = server(conf)[conf[:database]]
			# 		  end
			# 		  
			# 		  # Returns new RFM layout object
			# 	    # Use: layout('lay_name')
			# 	    # Use: layout('lay_name', :server=>{:some=>'hash'})
			# 	    # Use: layout(:layout=>'lay_name', :server=>{...})
			# 	  	def layout(*args)
			# 	  		return @layout if (@layout and args==[])
			# 	  		opt = args.last.is_a?(Hash) ? args.pop : {}
			# 	  	  layout_name = (args[0].class == String ? args[0] : nil)
			# 	      conf = config_merge_args(config_core.dup, opt)
			# 	      layout_name = (layout_name || conf[:layout])
			# 	      return {:error=>'Failed to get layout name', :args=>args, :opt=>opt, :conf=>conf, :layout_name=>layout_name} unless layout_name
			# 				# 	  	  server  = server(conf)
			# 				# 	  	  db      = conf[:database]
			# 				# 	  	  layout = server[db][layout_name]
			# 				# 	  	  layout.instance_variable_set(:@model, self.to_s)
			# 				# 	  	  @layout = layout
			# 				layout = db(conf)[layout_name]
			# 				layout.instance_variable_set(:@model, self.to_s)
			# 				@layout = layout
			# 	  	end
			
	  	def layout(*args)
	  		return @layout if (@layout and args==[])
	  		opt = args.last.is_a?(Hash) ? args.pop : {}
	  	  layout_name = (args[0].class == String ? args[0] : nil)
	      conf = config_merge_args(config_core.dup, opt)
				conf.merge!(:layout=>layout_name) if layout_name
				layout = Rfm::Factory.layout(conf)
				layout.instance_variable_set(:@model, self.to_s)
				@layout = layout
	  	end
	  	
	  	def_delegators :layout, :db, :server
	  
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
	    
	    def field_controls
	      @field_controls ||= self.layout.field_controls
	    end
	    
	    def field_names
	      field_controls.values.flatten.collect{|v| v.name}
	    end

		end # class << self
		
		# --- #
		
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
    
    
  protected
  
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
      return unless record_id
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
    
  	#config RFM_CONFIG if defined? RFM_CONFIG
  end # class Base
  

  # Methods for Rfm::Layout to build complex queries
  module ComplexQuery

		# Perform RFM find using complex boolean logic (multiple value options for a single field)
		# Mimics creation of multiple find requests for "or" logic
		# Use: rlayout_object.query({'fieldOne'=>['val1','val2','val3'], 'fieldTwo'=>'someValue', ...})
		def query(hash_or_recid, options = {})
		  if hash_or_recid.kind_of? Hash
		    get_records('-findquery', assemble_query(hash_or_recid), options)
		  else
		    get_records('-find', {'-recid' => hash_or_recid.to_s}, options)
		  end
		end

		# Build ruby params to send to -query action via RFM
		def assemble_query(query_hash)
			key_values, query_map = build_key_values(query_hash)
			key_values.merge("-query"=>query_translate(array_mix(query_map)))
		end

		# Build key-value definitions and query map  '-q1...'
		def build_key_values(qh)
			key_values = {}
			query_map = []
			counter = 0
			qh.each_with_index do |ha,i|
				ha[1] = ha[1].to_a
				query_tag = []
				ha[1].each do |v|
					key_values["-q#{counter}"] = ha[0]
					key_values["-q#{counter}.value"] = v
					query_tag << "q#{counter}"
					counter += 1
				end
				query_map << query_tag
			end
			return key_values, query_map
		end

		# Build query request logic for FMP requests  '-query...'
		def array_mix(ary, line=[], rslt=[])
			ary[0].to_a.each_with_index do |v,i|
				array_mix(ary[1,ary.size], (line + [v]), rslt)
				rslt << (line + [v]) if ary.size == 1
			end
			return rslt
		end

		# Translate query request logic to string
		def query_translate(mixed_ary)
			rslt = ""
			sub = mixed_ary.collect {|a| "(#{a.join(',')})"}
			sub.join(";")
		end

	end # module ComplexQuery



  ### Rfm direct class mods ###
  
  class Layout
  	require 'rfm/layout'
    include ComplexQuery
  end
    
        
  class Record
  	require 'rfm/record'
  	
  	class << self
	  	alias_method :new_orig, :new
	  	def new(record={}, result=[], field_meta='', layout=nil, portal=nil) # record, result, field_meta, layout, portal
	  		layout = layout rescue layout
	      model = eval(layout.instance_variable_get(:@model)) rescue Rfm::Record
	      #puts model.to_s
	      #puts model.class
	      #puts layout.instance_variable_get(:@model).to_s
	      if model.class == Rfm::Record
	      	new_orig(record, result, field_meta, layout, portal)
	      else
	      	model.new_orig(record, result, field_meta, layout, portal)
	      end
	    end
	  end

		alias_method :initialize_orig, :initialize
		def initialize(record, result, field_meta, layout, portal)
			if result == [] and  !record.has_key? 'field'   #!record.respond_to? :xpath
				@mods = Rfm::CaseInsensitiveHash.new
        # loop thru each layout field, creating hash keys with nil values
        self.class.field_controls.keys.each do |field| 
          field_name = field.to_s
          self[field_name] = nil
        end
        self.update_attributes(record) unless record == {}
        self.merge!(@mods) unless @mods == {}
      else
      	initialize_orig(record, result, field_meta, layout, portal)
      end
			yield(self) if block_given?
		end
    
  end # class Record

  
  module ImportFmp
    # TODO: fix mysql_import to be module & include it here
  	# See config/mysql_import.rb
  	# args: time-since-modified-as-anything, mapping-name, options-hash
  	# options-hash:  :modified_since=>time-as-anything, :mapping=>full-mapping, :layout=>fmp-layout-name, :fields=>{bb_field=>mysql_field}
  	# block: any code that returns rfm records, will be passed |var|
  	# result: [rmf_found_size, message, rfm_found_records]
  	def import_fmp_core(*args, &block)
  		log "import_fmp_core begin", table_name
  		options = args.extract_options! # See extract_options.rb when the Rails method becomes deprecated (2.3.8?)
  		modified_since =args[0] || options[:modified_since] || (Time.now - 2.hours)
  		modified_since_s = Time.parse(modified_since.to_s).strftime('%m/%d/%Y %T')
  		# Convert dates & times
  		mod_date_since, mod_time_since = Time.parse(modified_since.to_s).to_fm_components(true)
  		# Import field map
  		mapping = (mappings[args[1]] || options[:mapping] || mappings[:fm_import])
  		# Filemaker data
  		layout = options[:layout] || mapping[:layout]
  		fields = options[:fields] || mapping[:fields]
  		log("import_fmp_core", [options, args].to_yaml) if (Rails.logger.level == 0 and RAILS_ENV == :development)
  		if modified_since == 'all'
  			records = fm(layout).all
  		else
  			records = eval(block.call)
  		end
  		log "import_fmp_core found records", records.size
  		# Perform import, get [count, message] in return
  		rslt = self.import(fields, records, {:update=>true})
  		log "import_fmp_core end", table_name
  		# Return result
  		return (rslt << records)
  	end
  	alias_method :import_bb_core, :import_fmp_core
  	
  end # module ImportFmp
  
  
  class ::Time
  	# Returns array of [date,time] in format suitable for FMP.
  	def to_fm_components(reset_time_if_before_today=false)
  		d = self.strftime('%m/%d/%Y')
  		t = if (Date.parse(self.to_s) < Date.today) and reset_time_if_before_today==true
  			"00:00:00"
  		else
  			self.strftime('%T')
  		end
  		[d,t]
  	end
  end
  

  ### Enable this or put this in main_initializer to add ImportFmp to ActiveRecord models....
  # class ActiveRecord::Base
  #   require 'mysql_import'  # fix mysql_import to be module and include it above.
  #   extend ImportFmp
  # end
  
end # module Rfm



