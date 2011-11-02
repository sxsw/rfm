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
# TODO: make sure all methods return something (a record?) if successful, otherwise nil or error
# TODO: move rfm methods & patches from fetch_mail_with_ruby to this file


module Rfm

  
  # Methods to be included & extended into RfmHelper::Base
  module UniversalMethods
    ### These methods are included & extended ###
    
    # Sets @config with args. Two use forms:
    # config :key_name, :hash_item=>'', :hash_item2=>
    # config :key_name=>{:some=>'hash',...}, :key_name2=>{:someother=>'hash',...}
    # password will always be 'protected'
    def config(*args)
	    c = config_core(*args)
	    c[:password] = 'PROTECTED'
	    c
	  end
	  
	#protected
	  
	  # Unsecure, will return raw password
	  def config_core(*args)
	    @config ||= {}
	    @config.merge!(config_merge_args(@config, args))
	    config_get_merged
	  end
	  
	  # Get composite config from all levels
	  def config_get_merged
	    #puts "config_get_merged: #{self.to_s rescue ''} #{superclass.to_s rescue ''}"
      class_config = (self.class.config_get_merged rescue {})
      super_config = (self.superclass.config_get_merged rescue {})
      local_config = (@config rescue {})
      Hash.new.merge!(class_config).merge!(super_config).merge!(local_config)
    end
    # Get composite config from all 3 levels (Base, sub, instance)
    # def config_get_merged
    #       return {} unless @config
    #       conf_ary = [
    #         Base.instance_variable_get('@config'),
    #         self.class.instance_variable_get('@config'),
    #         self.instance_variable_get('@config')
    #   ]
    #   conf = {}
    #   conf_ary.each do |c|
    #     begin
    #       conf.merge! c
    #     rescue
    #     end
    #   end
    #   conf
    # end
	  
	  # Returns dup of conf with merged args
	  def config_merge_args(conf, args)
	    conf = conf.dup
  	  if args && args.class == Array
	  	  if args.size == 1
	  	    conf.merge! args[0]
	  	  elsif args && args.size == 2
	  	    name = args.shift
	  	    conf.merge!({name=>args[0]})
	      end
  	  elsif args && args.class == Hash
  	    conf.merge!(args)
      end
      ###	    
      return conf
    end

	end # module UniversalMethods
	
	
	### Class Methods ###
	# to be extended on RfmHelper::Base
	module ClassMethods
	  
	  # Returns RFM layout object
    # Use: fm_layout('lay_name')
    # Use: fm_layout('lay_name', :server=>{:some=>'hash'})
    # Use: fm_layout(:layout=>'lay_name', :server=>{...})
  	def fm_layout(*args)
  		opt = args.last.is_a?(Hash) ? args.pop : {}
  	  layout_name = (args[0].class == String ? args[0] : nil)
      conf = config_merge_args(config_core.dup, opt)
      layout_name = (layout_name || conf[:layout])
      return [args,opt,conf,layout_name] unless layout_name
  	  server  = Rfm::Server.new(conf)
  	  db      = conf[:database]
  	  #server.instance_variable_set('@model', self.to_s)
  	  layout = server[db][layout_name]
  	  layout.instance_variable_set(:@model, self.to_s)
  	  layout
  	end
	
  	# Returns RFM server object
  	def fm_server(*args)
      conf = config_merge_args(config_core.dup, args)
  	  server  = Rfm::Server.new(conf)
	  end
  
	  # Returns RFM db object
	  def fm_db(*args)
      conf = config_merge_args(config_core.dup, args)
  	  server  = Rfm::Server.new(conf)
  	  db      = conf[:database]
  	  server[db]
	  end
  
	  # Convenience methods
	  alias_method :fm, :fm_layout
    # alias_method :layout, :fm_layout
    # alias_method :server, :fm_server
    # alias_method :db,     :fm_db
	
  	def find(*args)
  	  r = fm_layout.find(*args)
  	  if args[0].class != Hash and r.size == 1
  	    r[0]
	    else
	      r
      end
    rescue Rfm::Error::RecordMissingError
      nil
  	end
	
  	def any(*args)
  	  fm_layout.any(*args)[0]
  	end
	
  	def create(*args)
  	  new(*args).send :create
  	end
  	
  	def create_from_instance(*args)
  	  fm_layout.create(*args)[0]
  	end
  
    # Using this method will skip callbacks. Use instance 'update' instead
	  def edit(*args)
	    fm_layout.edit(*args)[0]
    end
  
    # Using this method will skip callbacks. Use instance 'destroy' instead
    def delete(*args)
      fm_layout.delete(*args)
    end
    
    def query(*args)
      fm_layout.query(*args)
    end
    
    def field_controls
      @field_controls ||= self.fm_layout.field_controls
    end
    
    def field_names
      field_controls.values.flatten.collect{|v| v.name}
    end

	
  	# This will fire when a subclass is loaded (at the beginning of the subclass definition). Not currently used.
    # def inherited(sub)
    #   puts "SUB: " + sub.to_s
    # end
      
  end # module ClassMethods
  
  
  ### INSTANCE METHODS ###
  # to be included in RfmHelper::Base    	
  module InstanceMethods
  	
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
      input_hash = Rfm::Utility::CaseInsensitiveHash.new
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
    
    
  end # module InstanceMethods
	

  ### RfmHelper::Base (base model for new records) ###
  class Base <  Rfm::Record  #Hash
    #attr_accessor :record_id unless defined? record_id
    extend UniversalMethods
    include UniversalMethods
    extend ClassMethods
    include InstanceMethods
    begin
    	require 'active_model'
      include ActiveModel::Validations
      extend ActiveModel::Callbacks
      define_model_callbacks(:create, :update, :destroy)
    rescue
      alias_method(:run_callbacks, :callback_deadend)
    end
    
  	config FM_CONFIG if defined? FM_CONFIG
  end # class Base
  

  # Methods for Rfm::Layout to build complex queries
  module ComplexQuery

		# Perform RFM find using complex boolean logic (multiple value options for a single field)
		# Mimics creation of multiple find requests for "or" logic
		# Use: rfm_layout_object.query({'fieldOne'=>['val1','val2','val3'], 'fieldTwo'=>'someValue', ...})
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

	  
  # Used in Esalen web app
  class FMerror < Exception
  end
  BBerror = FMerror
  
  class Layout
  	require 'rfm/layout'
    include ComplexQuery
  end
  
  
	#   class Resultset
	#   	require 'rfm/resultset'    
	#     def initialize(server, xml_response, layout, portals=nil)
	#       @layout           = layout
	#       @server           = server
	#       @field_meta     ||= Rfm::CaseInsensitiveHash.new
	#       @portal_meta    ||= Rfm::CaseInsensitiveHash.new
	#       @include_portals  = portals 
	#       
	#       doc = Nokogiri.XML(remove_namespace(xml_response))
	#       
	#       error = doc.xpath('/fmresultset/error').attribute('code').value.to_i
	#       check_for_errors(error, server.state[:raise_on_401])
	# 
	#       datasource        = doc.xpath('/fmresultset/datasource')
	#       meta              = doc.xpath('/fmresultset/metadata')
	#       resultset         = doc.xpath('/fmresultset/resultset')
	# 
	#       @date_format      = convert_date_time_format(datasource.attribute('date-format').value)
	#       @time_format      = convert_date_time_format(datasource.attribute('time-format').value)
	#       @timestamp_format = convert_date_time_format(datasource.attribute('timestamp-format').value)
	# 
	#       @foundset_count   = resultset.attribute('count').value.to_i
	#       @total_count      = datasource.attribute('total-count').value.to_i
	# 
	#       parse_fields(meta)
	#       parse_portals(meta) if @include_portals
	#       
	#       model = eval(@layout.instance_variable_get(:@model)) rescue Rfm::Record
	#       model = model.superclass == Rfm::Record ? model : Rfm::Record
	#       model.build_records(resultset.xpath('record'), self, @field_meta, @layout)
	#       
	#     end # def initialize
	#     
	#   end # class Resultset 
    
        
  class Record
  	require 'rfm/record'
  	
  	class << self
	  	alias_method :new_orig, :new
	  	def new(record={}, result=[], field_meta='', layout=nil, portal=nil) # record, result, field_meta, layout, portal
	  		layout = fm_layout rescue layout
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
			if result == [] and !record.respond_to? :xpath
				@mods = Rfm::Utility::CaseInsensitiveHash.new
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
    
		#     def initialize(row_element={}, resultset=[], fields=self.class.field_controls, layout=self.class.fm_layout, portal=nil)
		#       @record_id = row_element['record-id']
		#       @mod_id = row_element['mod-id']
		#       @mods = Rfm::Utility::CaseInsensitiveHash.new
		#       @resultset = resultset
		#       @layout = layout
		# 
		#       @loaded = false
		#       related_sets = row_element.search('relatedset') rescue []
		#       
		#       # if new record from user, with or without data
		#       if resultset == [] and !row_element.respond_to? :search
		#         # loop thru each layout field, creating hash keys with nil values
		#         self.class.field_controls.keys.each do |field| 
		#           field_name = field.to_s
		#           self[field_name] = nil
		#         end
		#         self.update_attributes(row_element) unless row_element == {}
		#         self.merge!(@mods) unless @mods == {}
		#       end       
		#         
		#       if row_element.respond_to? :search
		#         row_element.search('field').each do |field| 
		#           field_name = field['name']
		#           field_name.sub!(Regexp.new(portal + '::'), '') if portal
		#           datum = []
		#           field.search('data').each do |x| 
		#             datum.push(fields[field_name].coerce(x.inner_text))
		#           end
		#           if datum.length == 1
		#             self[field_name] = datum[0]
		#           elsif datum.length == 0
		#             self[field_name] = nil
		#           else
		#             self[field_name] = datum
		#           end
		#         end
		#       end
		# 
		#       unless related_sets.empty?
		#         @portals = Rfm::Utility::CaseInsensitiveHash.new
		#         related_sets.each do |relatedset|
		#           table = relatedset['table']
		#           records = []
		#           relatedset.search('record').each do |record|
		#             records << Record.new(record, @resultset, @resultset.portals[table], @layout, table)
		#           end
		#           @portals[table] = records
		#         end
		#       end
		#       @loaded = true
		#       yield(self) if block_given?
		#     end # def initialize

    def []=(pname, value)
      return super unless @loaded # keeps us from getting mods during initialization
      name = pname
      if self[name] != nil
        @mods[name] = value
        self.merge! @mods unless @mods == {}
      else
        raise Rfm::Error::ParameterError.new("You attempted to modify a field called '#{name}' on the Rfm::Record object, but that field does not exist.")
      end
    end
    
    def method_missing (symbol, *attrs)
      # check for simple getter
      return self[symbol.to_s] if self.include?(symbol.to_s) 

      # check for setter
      symbol_name = symbol.to_s
      if symbol_name[-1..-1] == '=' && self.has_key?(symbol_name[0..-2])
        rslt = @mods[symbol_name[0..-2]] = attrs[0]
        @mods[symbol_name[0..-2]] = attrs[0]
        self.merge! @mods
        return rslt
      end
      super
    end
    
    def save
      save!
    rescue
      self.errors[:base] << $1
      return nil
    end

    # Like Record::save, except it fails (and raises an error) if the underlying record in FileMaker was
    # modified after the record was fetched but before it was saved. In other words, prevents you from
    # accidentally overwriting changes someone else made to the record.
    def save_if_not_modified
      # was @layout.edit. Changed to handle before/after callbacks.
      # r = self.merge(edit(@record_id, @mods, {:modification_id => @mod_id})[0]) if @mods.size > 0
      # @mods.clear
      # r || {}
      update(@mod_id) if @mods.size > 0
    end
    
  end # class Record
  
  
  module Utility
    class CaseInsensitiveHash < Hash
      def []=(key, value)
        super(key.to_s.downcase, value)
      end
      def [](key)
        super(key.to_s.downcase)
      end
    end
  end # module Utility
    
  	

  
  
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
  
  	def import_bb_core(*args, &block)
  		log "import_fmp_core begin", table_name
  		options = args.extract_options! # See extract_options.rb when the Rails method becomes deprecated (2.3.8?)
  		var = {} # Store all local variables in an array, to be passed to block
  		var[:modified_since] =  args[0] || options[:modified_since] || (Time.now - 2.hours)
  		var[:modified_since_s] = Time.parse(var[:modified_since].to_s).strftime('%m/%d/%Y %T')
  		modified_since_s = var[:modified_since_s]
  		# Convert dates & times
  		var[:mod_date_since], var[:mod_time_since] = Time.parse(var[:modified_since].to_s).to_fm_components(true)
  		# Import field map
  		var[:mapping] = (mappings[args[1]] || options[:mapping] || mappings[:bb_import])
  		# Filemaker data
  		var[:layout] = options[:layout] || var[:mapping][:layout]
  		var[:fields] = options[:fields] || var[:mapping][:fields]
  		log("import_bb_core var", var.to_yaml) if (Rails.logger.level == 0 and RAILS_ENV == :development)
  		if var[:modified_since] == 'all'
  			records = fm(var[:layout]).all
  		else
  			records = yield(var)
  			#records = &meth.instance_eval(&block)
  		end
  		log "import_bb_core found records", records.size
  		# Perform import, get [count, message] in return
  		rslt = self.import(var[:fields], records, {:update=>true})
  		log "import_bb_core end", table_name
  		# Return result
  		return (rslt << records)
  	end
  	
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


### Example model definitions ###
# class Person < RfmHelper::Base
#   config :account_name=>'someaccount', :host=>'http://cerne05.cernesystems.com', :database=>'SevenGables'
# end
# 
# class Memo < RfmHelper::Base
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


