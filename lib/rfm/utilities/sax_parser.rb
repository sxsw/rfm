# ####  A declarative SAX parser, written by William Richardson  #####
#
# Use:
#   irb -rubygems -I./  -r  lib/rfm/utilities/sax_parser.rb
#   Handler.build(
#     <xml-string or xml-file-path or file-io or string-io>,
#     <optional: parsing-backend-lable or custom-backend-handler>,
#     <optional: configuration-yml-file or yml-string or config-hash>
#   )
#
# Note: 'attach: none' puts the object in the cursor & stack but does not attach it to the parent.
#       'ignore: self' prevents the object from entering the cursor or stack.
#				Both of these will still allow processing of attributes and subelements.
#   
# Examples:
#   r = Rfm::SaxParser::Handler.build('some/file.xml')  # => defaults to best xml backend with no parsing configuration.
#   r = Rfm::SaxParser::Handler.build('some/file.xml', :ox)  # => uses ox backend or throws error.
#   r = Rfm::SaxParser::Handler.build('some/file.xml', :rexml, {:compact=>true})  # => uses inline configuration.
#   r = Rfm::SaxParser::Handler.build('some/file.xml', :nokogiri, 'path/to/config.yml')  # => loads config from yml file.
#
# Sandbox:
#   irb -rubygems -I./  -r  local_testing/sax_parser_sandbox.rb
#   > r = Sandbox.parse(:fm <optional: , :rexml, {:compact=>true} >)
#
# ####  CONFIGURATION  #####
#
# YAML structure defining a SAX xml parsing template.
# Options:
#   initialize:									array: initialize new objects with this code [:method, params] instead of defaulting to 'allocate'
#   elements:										array of element hashes {'name'=>'element-tag'}
#   attributes:									array of attribute hashes {'name'=>'attribute-name'} UC
#   class:											string-or-class: class name for new element
#   depth:											integer: depth-of-default-class UC
#		attach:											string: shared, instance, hash, array, cursor, none - attach this element or attribute to parent. 
#		attach_elements:						string: same as 'attach' - for all subelements, unless they have their own 'attach' specification
#		attach_attributes:					string: same as 'attach' - for all attributes, unless they have their own 'attach' specification
#   before_close:								method-name-as-symbol: run a model method before closing tag
#   each_before_close:					method-name-as-symbol
#   as_name:										string: store element or attribute keyed as specified
#   delineate_with_hash:				string: attribute/hash key to delineate objects with identical tags
#
#
#gem('ox', '1.8.5') if RUBY_VERSION[2].to_i > 8
require 'stringio'
require 'ox'
require 'yaml'
require 'rexml/streamlistener'
require 'rexml/document'
require 'libxml'
require 'nokogiri'

# done: Move test data & user models to spec folder and local_testing.
# done: Create special file in local_testing for experimentation & testing - will have user models, grammar-yml, calling methods.
# done: Add option to 'compact' unnecessary or empty elements/attributes - maybe - should this should be handled at Model level?
# na  : Separate all attribute options in yml into 'attributes:' hash, similar to 'elements:' hash.
# TODO: Handle multiple 'text' callbacks for a single element.
# done: Add options for text handling (what to name, where to put).
# done: Fill in other configuration options in yml
# done: Clean_elements doesn't work if elements are non-hash/array objects. Make clean_elements work with object attributes.
# TODO: Clean_elements may not work for non-hash/array objecs with multiple instance-variables.
# TODO: Clean_elements may no longer work with a globally defined 'compact'.
# TODO: Do we really need Cursor#top and Cursor#stack ? Can't we get both from stack?
# TODO: When using a non-hash/array object as the initial object, things get kinda srambled.
#       See Rfm::Connection, when sending self (the connection object) as the initial_object.
# done: 'compact' breaks badly with fmpxmllayout data.
# na  : Do the same thing with 'ignore' as you did with 'attach', so you can enable using the 'attributes' array of the yml model.
# done: Double-check that you're pointing to the correct model/submodel, since you changed all helper-methods to look at curent-model by default.
# done: Make sure all method calls are passing the model given by the calling-method.
# TODO: Give most of the config options a global possibility.
# na  : Block attachment methods from seeing parent if parent isn't the current objects true parent (how?).
# done: Handle attach: hash better (it's not specifically handled, but declaring it will block a parents influence).
# TODO: CaseInsensitiveHash/IndifferentAccess is not working for sax parser.
# TODO: Give the yml (and xml) doc the ability to have a top-level hash like "fmresultset" or "fmresultset_yml" or "fmresultset_xml",
#       then you have a label to refer to it if you load several config docs at once (like into a Rfm::SaxParser::TEMPLATES constant).
#       Use an array of accepted model-keys  to filter whether loaded template is a named-model or actual model data.
# done: Load up all template docs when Rfm loads, or when Rfm::SaxParser loads. For RFM only, not for parser module.
# done: Move SaxParser::Handler class methods to SaxParser, so you can do Rfm::SaxParser.parse(io, backend, template, initial_object)
# done: Switch args order in .build methods to (io, template, initial_object, backend)
# done: Change "grammar" to "template" in all code
# done: Change 'cursor._' methods to something more readable, since they will be used in Rfm and possibly user models.
# done: Split off template loading into load_templates and/or get_templates methods.
# TODO: Something is downcasing somewhere - see the fmpxmllayout response. Looks like 'compact' might have something to do with it.
# done: Make attribute attachment default to individual.
# done: 'attach: shared' doesnt work yet for elements.
# na  : Arrays should always get elements attached to their records and attributes attached to their instance variables. 
# done: Merge 'ignore: self, elements, attributes' config into 'attach: ignore, attach_elements: ignore, attach_attributes: ignore'.
# done: Consider having one single group of methods to attach all objects (elements OR attributes OR text) to any given parent object.
# na  : May need to store 'ignored' models in new cursor, with the parent object instead of the new object. Probably not a good idea
# done: Fix label_or_tag for object-attachment.
# done: Fix delineate_with_hash in parsing of resultset field_meta (should be hash of hashes, not array of hashes).
# TODO: Test new parser with raw data from multiple sources, make sure it works as raw.
# TODO: Make sure single-attribute (or text) handler has correct objects & models to work with.
# na  : Rewrite attach_to_what? logic to start with base_object type, then have sub-case statements for the rest.



module Rfm
	module SaxParser
	
		(DEFAULT_CLASS = Hash) unless defined? DEFAULT_CLASS
		
		# Use :libxml, or anything else, if you want it to always default
		# to something other than the fastest backend found.
		# Nil will let the user or the gem decide. Specifying a label here will force or throw error.
		(DEFAULT_BACKEND = nil) unless defined? DEFAULT_BACKEND
		
		(DEFAULT_TEXT_LABEL = 'text') unless defined? DEFAULT_TEXT_LABEL
		
		(DEFAULT_TAG_TRANSLATION = [/\-/, '_']) unless defined? DEFAULT_TAG_TRANSLATION
		
		(DEFAULT_SHARED_INSTANCE_VAR = 'attributes') unless defined? DEFAULT_SHARED_INSTANCE_VAR		
		
		(BACKENDS = [[:ox, 'ox'], [:libxml, 'libxml-ruby'], [:nokogiri, 'nokogiri'], [:rexml, 'rexml/document']]) unless defined? BACKENDS
		
		OPTIONS = [:name, :elements, :attributes, :attach, :attach_elements, :attach_attributes, :compact,
							:depth, :before_close, :each_before_close, :delineate_with_hash, :as_name, :initialize
							]
							
		(TEMPLATES = {}) unless defined? TEMPLATES
		
		def self.parse(*args)
			Handler.build(*args)
		end

		
		class Cursor
		
		    attr_accessor :model, :object, :tag, :parent, :top, :stack, :newtag
		    
		    def self.test_class
		    	Record
		    end
		    def test_class
		    	Record
		    end
		    
		    # Main get-constant method
		    def self.get_constant(klass)
		    	return DEFAULT_CLASS if klass.to_s == ''
		    	return klass unless klass.is_a?(String) || klass.is_a?(Symbol)
		    	klass = klass.to_s
		    	
		    	# Added to evaluate fully-qualified class names
		    	return eval(klass.to_s) if klass.to_s && klass.to_s[/::/]
		    	
		    	# TODO: This can surely be cleaned up.
		    	case
			    	when const_defined?(klass); const_get(klass)
			    	when self.ancestors[0].const_defined?(klass); self.ancestors[0].const_get(klass)
			    	when SaxParser.const_defined?(klass); SaxParser.const_get(klass)
			    	#when object.const_defined?(klass); _object.const_get(klass)
				  	when Module.const_defined?(klass); Module.const_get(klass)
				  	else puts "Could not find constant '#{klass.to_s}'"; DEFAULT_CLASS
			  	end
			  end
		    
		    def initialize(_model, _obj, _tag)
		    	@tag   = _tag
		    	@model = _model
		    	@object   = _obj.is_a?(String) ? get_constant(_obj).new : _obj
		    	self
		    end
		    
		    
		    
		    #####  SAX METHODS  #####
		    
			  def attribute(name, value)
			  	assign_attributes({name=>value}, object, model, model)
			  rescue
			  	puts "Error: could not assign attribute '#{name.to_s}' to element '#{self.tag.to_s}': #{$!}"
			  end
		        
		    def start_el(_tag, _attributes)		
		    	#puts "Start_el: _tag '#{_tag}', cursorobject '#{object.class}', cursor_submodel '#{submodel.to_yaml}'."
		    	
		    	# Set newtag for other methods to use during the start_el run.
		    	self.newtag = _tag
		
		    	# Acquire submodel definition.
		      subm = submodel
		      
		    	if attachment_prefs(model, subm, 'element')=='none'
		    		assign_attributes(_attributes, object, subm, subm)
		    		return
		    	end		      
		      
		      # Create new element.
		      #new_element = (get_constant((subm['class']).to_s) || Hash).new
		      #new_element = get_constant(subm['class']).send(*[(allocate(subm) ? :allocate : :new), (initialize_with(subm) ? eval(initialize_with(subm)) : nil)].compact)
		      #new_element = get_constant(subm['class']).send(*[(allocate(subm) ? :allocate : :new), (initialize_with(subm) ? eval(initialize_with(subm)) : nil)].compact)
		      const = get_constant(subm['class'])
		      init = initialize?(subm) || []
		      init[0] ||= :allocate
		      init[1] = eval(init[1].to_s)
		      new_element = const.send(*init.compact)
		      #puts "Created new element of class '#{new_element.class}' for _tag '#{tag}'."
		      
		      # Assign attributes to new element.
		      assign_attributes(_attributes, new_element, subm, subm)

					# Attach new element to cursor _object
					#attach_new_object_master(subm, new_element)
					attach_new_object(object, new_element, newtag, model, subm, 'element')
		  		
		  		returntag = newtag
		  		self.newtag = nil
		      return Cursor.new(subm, new_element, returntag)
		    end # start_el
		
		    def end_el(_tag)
		      if _tag == self.tag
		      	begin
		      		# Data cleaup
							(clean_members {|v| clean_members(v){|v| clean_members(v)}}) if compact? #top.model && top.model['compact']
			      	# This is for arrays
			      	object.send(before_close?.to_s, self) if before_close?
			      	# TODO: This is for hashes with array as value. It may be ilogical in this context. Is it needed?
			      	if each_before_close? && object.respond_to?('each')
			      	  object.each{|o| o.send(each_before_close?.to_s, object)}
		      	  end
			      rescue
			      	puts "Error ending element tagged '#{_tag}': #{$!}"
			      end
		        return true
		      end
		    end



				#####  MERGE METHODS  #####
				
		  	# Assign attributes to element.
				def assign_attributes(_attributes, base_object, base_model, new_model)
		      if _attributes && !_attributes.empty?
						_attributes.each{|k,v| attach_new_object(base_object, v, k, base_model, model_attributes?(k, new_model), 'attribute')}
		      end
				end

				def attach_new_object(base_object, new_object, name, base_model, new_model, type)
					label = label_or_tag(name, new_model)
					assignment = attach_to_what?(base_object, new_object, label, base_model, new_model, type)
					#puts "attach_new_object: BO '#{base_object.class}' BM '#{base_model['name'] rescue ''}' NO '#{new_object.class}' NM '#{new_model['name'] rescue ''}' N '#{name}' T '#{type}' p '#{assignment}'"
					case assignment;
						when 'shared'; merge_with_shared(base_object, new_object, label, new_model)
						when 'instance'; merge_with_instance(base_object, new_object, label, new_model)
						when 'hash'; merge_with_hash(base_object, new_object, label, new_model)
						when 'array'; merge_with_array(base_object, new_object, label, new_model)
					end
				end
				
				def attachment_prefs(base_model, new_model, type)
					case type
						when 'element'; attach?(new_model) || attach_elements?(base_model)
						when 'attribute'; attach?(new_model) || attach_attributes?(base_model)
					end
				end
				
				def attach_to_what?(base_object, new_object, name, base_model, new_model, type)
					prefs = attachment_prefs(base_model, new_model, type)
					
					case
						when prefs=='shared'; 'shared'
						when prefs=='instance' || (type=='attribute' && base_object.is_a?(Array)) || (prefs.nil? && !base_object.is_a?(Hash)); 'instance'
						when base_object.is_a?(Hash) && (prefs.nil? || prefs.to_s[/hash/]); 'hash'
						when base_object.is_a?(Array) && (type='element' || prefs=='array'); 'array'
						when prefs=='cursor'; 'cursor'
						when prefs=='none' ; 'none'				
					end					
				end

		    def merge_with_shared(base_object, new_object, label, new_model)
		    	ivg(DEFAULT_SHARED_INSTANCE_VAR, base_object) || set_attr_accessor(DEFAULT_SHARED_INSTANCE_VAR, {}, base_object)
  			  if ivg(DEFAULT_SHARED_INSTANCE_VAR, base_object)[label]
					  ivg(DEFAULT_SHARED_INSTANCE_VAR, base_object)[label] = merge_objects(ivg(label), new_object, new_model)
					else
					  ivg(DEFAULT_SHARED_INSTANCE_VAR, base_object)[label] = new_object
				  end
		    end
		    
		    def merge_with_instance(base_object, new_object, label, new_model)
  			  if ivg(label, base_object)
					  ivs(label, merge_objects(ivg(label, base_object), new_object, new_model), base_object)
					else
					  set_attr_accessor(label, new_object, base_object)
				  end
		    end
		    
		    def merge_with_hash(base_object, new_object, label, new_model)
    			if base_object[label]
  					base_object[label] = merge_objects(base_object[label], new_object, new_model)
  			  else			
  	  			base_object[label] = new_object
    			end
		    end
		    
		    # TODO: Does this really need to use merge_elements?
		    def merge_with_array(base_object, new_object, label, new_model)
					if base_object.size > 0
						base_object.replace merge_objects(base_object, new_object, new_model)
					else
  	  			base_object << new_object
	  			end
		    end

		    def merge_objects(base_object, new_object, new_model)
		    	# delineate_with_hash is the attribute name to match on.
		    	# current_key/new_key is the actual value of the match object.
		    	# current_key/new_key is then used as a hash key to contain objects that match on the delineate_with_hash attribute.
		    	#puts "merge_objects with tags '#{self.tag}/#{label_or_tag}' current_el '#{current_object.class}' and new_el '#{new_object.class}'."
	  	  	begin
		  	    current_key = get_attribute(delineate_with_hash?(new_model), base_object)
		  	    new_key = get_attribute(delineate_with_hash?(new_model), new_object)
		  	    #puts "merge_objects: tag '#{tag}', new '#{newtag}', delineate-with-hash '#{delineate_with_hash?(submodel)}', current-key '#{current_key}', new-key '#{new_key}'"
		  	    
		  	    key_state = case
		  	    	when !current_key.to_s.empty? && current_key == new_key; 5
		  	    	when !current_key.to_s.empty? && !new_key.to_s.empty?; 4
		  	    	when current_key.to_s.empty? && new_key.to_s.empty?; 3
		  	    	when !current_key.to_s.empty?; 2
		  	    	when !new_key.to_s.empty?; 1
		  	    	else 0
		  	    end
		  	  
		  	  	case key_state
			  	  	when 5; {current_key => [base_object, new_object]}
			  	  	when 4; {current_key => base_object, new_key => new_object}
			  	  	when 3; [base_object, new_object].flatten
			  	  	when 2; {current_key => ([*base_object] << new_object)}
			  	  	when 1; base_object.merge(new_key=>new_object)
			  	  	else    [base_object, new_object].flatten
		  	  	end
		  	  	
	  	    rescue
	  	    	puts "Error: could not merge with hash: #{$!}"
	  	    	#([*current_object] << new_object) if current_object.is_a?(Array)
	  	    end
		    end # merge_objects




		    #####  UTILITY  #####
		
			  def get_constant(klass)
			  	self.class.get_constant(klass)
			  end
			  
			  # Methods for current _model
			  def ivg(name, _object=object); _object.instance_variable_get "@#{name}"; end
			  def ivs(name, value, _object=object); _object.instance_variable_set "@#{name}", value; end
			  def model_elements?(which=nil, _model=model); (_model['elements'] && which ? _model['elements'].find{|e| e['name']==which} : _model['elements']) ; end
			  def model_attributes?(which=nil, _model=model); (_model['attributes'] && which ? _model['attributes'].find{|a| a['name']==which} : _model['attributes']) ; end
			  def depth?(_model=model); _model['depth']; end
			  def before_close?(_model=model); _model['before_close']; end
			  def each_before_close?(_model=model); _model['each_before_close']; end
			  def compact?(_model=model); _model['compact'] || top.model['compact']; end
			  def attach?(_model=model); _model && _model['attach']; end
			  def attach_elements?(_model=model); _model['attach_elements']; end
			  def attach_attributes?(_model=model); _model['attach_attributes']; end
			  def delineate_with_hash?(_model=model); _model['delineate_with_hash']; end
			  def as_name?(_model=model); _model && _model['as_name']; end
			  def initialize?(_model=model); _model['initialize']; end

			  # Methods for submodel
				def submodel(_tag=newtag); get_submodel(_tag) || default_submodel; end
				def label_or_tag(_tag=newtag, _model=submodel); as_name?(_model) || _tag; end
		  	
				def get_submodel(name)
					model_elements?(name)
				end
				
				def default_submodel
					#puts "Using default submodel"
					# Depth is not used yet.
					if depth?.to_i > 0
						{'elements' => model_elements?, 'depth'=>(depth?.to_i - 1)}
					else
						DEFAULT_CLASS.new
					end
				end
				
		    def get_attribute(name, obj=object)
		    	return unless name
		    	key = DEFAULT_SHARED_INSTANCE_VAR
		    	case
		    		when (obj.respond_to?(key) && obj.send(key)); obj.send(key)[name]
		    		when (r= ivg(name, obj)); r
		    		else obj[name]
		    	end
		    end
		    
		    def set_attr_accessor(name, data, obj=object)
					create_accessor(name, obj)
					obj.instance_eval do
						var = instance_variable_get("@#{name}")
						#puts "Assigning @att attributes for '#{obj.class}' #{data.to_a.join(':')}"
						case
						when data.is_a?(Hash) && var.is_a?(Hash); var.merge!(data)
						when data.is_a?(String) && var.is_a?(String); var << data
						when var.is_a?(Array); [var, data].flatten!
						else instance_variable_set("@#{name}", data)
						end
					end
				end
								
				def create_accessor(_tag, obj=object)
					obj.class.send :attr_accessor, _tag unless obj.instance_variables.include?(":@#{_tag}")
				end
				
		    def clean_members(obj=object)
	    		if obj.is_a?(Hash)
	    			obj.dup.each do |k,v|
	    				obj[k] = clean_member(v)
	    				yield(v) if block_given?
	    			end
	    		elsif obj.is_a?(Array)
	    			obj.dup.each_with_index do |v,i|
	    				obj[i] = clean_member(v)
	    				yield(v) if block_given?
	    			end
	    		else	
						obj.instance_variables.each do |var|
							dat = obj.instance_variable_get(var)
							obj.instance_variable_set(var, clean_member(dat))
							yield(dat) if block_given?
						end
	    		end
	    	end
	    	
	    	def clean_member(val)
	    		if val.is_a?(Hash) || val.is_a?(Array); 
						if val && val.empty?
							nil
						elsif val && val.respond_to?(:values) && val.size == 1
							val.values[0]
						else
							val
						end
					else
						val
						# Probably shouldn't do this on instance-var values. ...Why not?
						# 	if val.instance_variables.size < 1
						# 		nil
						# 	elsif val.instance_variables.size == 1
						# 		val.instance_variable_get(val.instance_variables[0])
						# 	else
						# 		val
						# 	end
					end
	    	end
		
		end # Cursor
		
		
		
		#####  SAX HANDLER  #####
		
		module Handler
		
			attr_accessor :stack, :template

			def self.build(io, template=nil, initial_object=DEFAULT_CLASS.new, backend=DEFAULT_BACKEND)
				backend = decide_backend unless backend
				backend = (backend.is_a?(String) || backend.is_a?(Symbol)) ? SaxParser.const_get(backend.to_s.capitalize + "Handler") : backend
			  backend.build(io, template, initial_object)
		  end
		  
		  def self.included(base)
		    def base.build(io, template=nil, initial_object= DEFAULT_CLASS.new)
		  		handler = new(template, initial_object)
		  		handler.run_parser(io)
		  		#handler._stack[0].object
		  		handler
		  	end
		  end # self.included
		  
		  def self.decide_backend
		  	BACKENDS.find{|b| !Gem::Specification::find_all_by_name(b[1]).empty?}[0]
		  rescue
		  	raise "The xml parser could not find a loadable backend gem: #{$!}"
		  end
		  
		  def initialize(_template=nil, initial_object = DEFAULT_CLASS.new)
		  	@stack = []
		  	@template = get_template(_template)
		  	#(@template = @template.values[0]) if @template.size == 1
		  	#y @template
		  	init_element_buffer
		    set_cursor Cursor.new(@template, initial_object, 'top')
		  end
		  
			def get_template(name)
				dat = TEMPLATES[name]
				if dat
					rslt = load_template(dat)
				else
					rslt = load_template(name)
				end
				(TEMPLATES[name] = rslt) #unless dat == rslt
			end
			
			def load_template(dat)
				prefix = defined?(TEMPLATE_PREFIX) ? TEMPLATE_PREFIX : ''
		  	rslt = case
		  		when dat.is_a?(Hash); dat
		  		when dat.to_s[/\.y.?ml$/i]; (YAML.load_file(File.join(prefix, dat)))
		  		# This line might cause an infinite loop.
		  		when dat.to_s[/\.xml$/i]; self.class.build(File.join(prefix, dat), nil, {'compact'=>true})
		  		when dat.to_s[/^<.*>/i]; "Convert from xml to Hash - under construction"
		  		when dat.is_a?(String); YAML.load dat
		  		else DEFAULT_CLASS.new
		  	end
			end
		  
		  def result
		  	stack[0].object if stack[0].is_a? Cursor
		  end
		  
			def cursor
				stack.last
			end
			
			def set_cursor(args) # cursor-_object
				if args.is_a? Cursor
					stack.push(args)
					cursor.parent = stack[-2] || stack[0] #_stack[0] so methods called on parent won't bomb.
					cursor.top = stack[0]
					cursor.stack = stack
				end
				cursor
			end
			
			def dump_cursor
				stack.pop
			end
			
			def transform(name)
				return name unless DEFAULT_TAG_TRANSLATION.is_a?(Array)
				name.to_s.gsub(*DEFAULT_TAG_TRANSLATION)
			end
			
			def init_element_buffer
		    @element_buffer = {:tag=>nil, :attributes=>DEFAULT_CLASS.new}
			end
			
			def send_element_buffer
		    if element_buffer?
          set_cursor cursor.start_el(@element_buffer[:tag], @element_buffer[:attributes])
          init_element_buffer
	      end
	    end
	    
	    def element_buffer?
	      @element_buffer[:tag] && !@element_buffer[:tag].empty?
	    end
		
		  # Add a node to an existing element.
			def _start_element(tag, attributes=nil, *args)
				#puts "Receiving element '#{_tag}' with attributes '#{attributes}'"
				tag = transform tag
				send_element_buffer
				if attributes
					# This crazy thing transforms attribute keys to underscore (or whatever).
					attributes = DEFAULT_CLASS[*attributes.collect{|k,v| [transform(k),v] }.flatten]
					set_cursor cursor.start_el(tag, attributes)
				else
				  @element_buffer = {:tag=>tag, :attributes => DEFAULT_CLASS.new}
				end
			end
			
			# Add attribute to existing element.
			def _attribute(name, value, *args)
				#puts "Receiving attribute '#{name}' with value '#{value}'"
				name = transform name
		    #cursor.attribute(name,value)
				@element_buffer[:attributes].merge!({name=>value})
			end
			
			# Add 'content' attribute to existing element.
			def _text(value, *args)
				#puts "Receiving text '#{value}'"
				return unless value.to_s[/[^\s]/]
				if element_buffer?
				  @element_buffer[:attributes].merge!({DEFAULT_TEXT_LABEL=>value})
				  send_element_buffer
				else
					cursor.attribute(DEFAULT_TEXT_LABEL, value)
				end
			end
			
			# Close out an existing element.
			def _end_element(tag, *args)
				tag = transform tag
				#puts "Receiving end_element '#{tag}'"
	      send_element_buffer
	      cursor.end_el(tag) and dump_cursor
			end
		  
		end # Handler
		
		
		
		#####  SAX PARSER BACKEND HANDLERS  #####
		
		class OxHandler < ::Ox::Sax
		  include Handler
		
		  def run_parser(io)
				case
				when (io.is_a?(File) or io.is_a?(StringIO)); Ox.sax_parse self, io
				when io.to_s[/^</]; StringIO.open(io){|f| Ox.sax_parse self, f}
				else File.open(io){|f| Ox.sax_parse self, f}
				end
			end
			
			alias_method :start_element, :_start_element
			alias_method :end_element, :_end_element
			alias_method :attr, :_attribute
			alias_method :text, :_text		  
		end # OxFmpSax


		class RexmlHandler
			# Both of these are needed to use rexml streaming parser,
			# but don't put them here... put them at the _top.
			#require 'rexml/streamlistener'
			#require 'rexml/document'
			include REXML::StreamListener
		  include Handler
		
		  def run_parser(io)
		  	parser = REXML::Document
				case
				when (io.is_a?(File) or io.is_a?(StringIO)); parser.parse_stream(io, self)
				when io.to_s[/^</]; StringIO.open(io){|f| parser.parse_stream(f, self)}
				else File.open(io){|f| parser.parse_stream(f, self)}
				end
			end
			
			alias_method :tag_start, :_start_element
			alias_method :tag_end, :_end_element
			alias_method :text, :_text
		end # RexmlStream
		
		
		class LibxmlHandler
			include LibXML
			include XML::SaxParser::Callbacks
		  include Handler
		
		  def run_parser(io)
				parser = case
					when (io.is_a?(File) or io.is_a?(StringIO)); XML::SaxParser.io(io)
					when io[/^</]; XML::SaxParser.io(StringIO.new(io))
					else XML::SaxParser.io(File.new(io))
				end
				parser.callbacks = self
				parser.parse	
			end
			
			alias_method :on_start_element_ns, :_start_element
			alias_method :on_end_element_ns, :_end_element
			alias_method :on_characters, :_text
		end # LibxmlSax	
		
		
		class NokogiriHandler < Nokogiri::XML::SAX::Document
		  include Handler
		
		  def run_parser(io)
				parser = Nokogiri::XML::SAX::Parser.new(self)	  
				parser.parse(case
					when (io.is_a?(File) or io.is_a?(StringIO)); io
					when io[/^</]; StringIO.new(io)
					else File.new(io)
				end)
			end

			alias_method :start_element, :_start_element
			alias_method :end_element, :_end_element
			alias_method :characters, :_text
		end # NokogiriSax	
		


	end # SaxParser
end # Rfm

