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
require 'yaml'
require 'forwardable'
require 'stringio'
# require 'rexml/streamlistener'
# require 'rexml/document'
# require 'ox'
# require 'libxml'
# require 'nokogiri'

# done: Move test data & user models to spec folder and local_testing.
# done: Create special file in local_testing for experimentation & testing - will have user models, grammar-yml, calling methods.
# done: Add option to 'compact' unnecessary or empty elements/attributes - maybe - should this should be handled at Model level?
# na  : Separate all attribute options in yml into 'attributes:' hash, similar to 'elements:' hash.
# done: Handle multiple 'text' callbacks for a single element.
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
# na  : Give the yml (and xml) doc the ability to have a top-level hash like "fmresultset" or "fmresultset_yml" or "fmresultset_xml",
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
# done: Test new parser with raw data from multiple sources, make sure it works as raw.
# done: Make sure single-attribute (or text) handler has correct objects & models to work with.
# na  : Rewrite attach_to_what? logic to start with base_object type, then have sub-case statements for the rest.
# done: Build backend-gem loading scheme. Eliminate gem 'require'. Use catch/throw like in XmlParser.
# done: Splash_sax.rb is throwing error when loading User.all when SaxParser.backend is anything other than :ox.
#       This is probably related to the issue of incomming attributes (that are after the incoming start_element) not knowing their model.
#       Some multiple-text attributes were tripping up delineate_with_hash, so I added some fault-tollerance to that method.
#       But those multi-text attributes are still way ugly when passed by libxml or nokogiri. Ox & Rexml are fine and pass them as one chunk.
#       Consider buffering all attributes & text until start of new element.
# YAY :  I bufffered all attributes & text, and the problem is solved.
# na  : Can't configure an attribute (in template) if it is used in delineate_with_hash. (actually it works if you specifiy the as_name: correctly).
# TODO: Some configurations in template cause errors - usually having to do with nil.
# done: Can't supply custom class if it's a String (but an unspecified subclass of plain Object works fine!?).
# TODO: Attaching non-hash/array object to Array will thro error. Is this actually fixed?
# done?: Sending elements with subelements to Shared results in no data attached to the shared var.
# TODO: compact is not working for fmpxmllayout-error
# TODO: Add ability to put a regex in the as_name parameter, that will operate on the tag/label/name.
# TODO: Optimize:
#				Use variables, not methods.
#				Use string interpolation not concatenation.
#				Use destructive! operations (carefully). Really?
#				Get this book: http://my.safaribooksonline.com/9780321540034?portal=oreilly
#				See this page: http://www.igvita.com/2008/07/08/6-optimization-tips-for-ruby-mri/
# done: Consider making default attribute-attachment shared, instead of instance.
# done: Find a way to get SaxParser defaults into core class patches.
# done: Check resultset portal_meta in Splash Asset model for field-definitions coming out correct according to sax template.
# done: Make sure Rfm::Metadata::Field is being used in portal-definitions.
# done: Scan thru Rfm classes and use @instance variables instead of their accessors, so sax-parser does less work.
# TODO: Change 'instance' option to 'private'. Change 'shared' to <whatever>.
# TODO: Since unattached elements won't callback, add their callback to an array of procs on the current cursor at the beginning
#				of the non-attached tag.





module Rfm
	module SaxParser
		extend Forwardable

		PARSERS = {}
		BACKENDS = [[:libxml, 'libxml-ruby'], [:nokogiri, 'nokogiri'], [:ox, 'ox'], [:rexml, 'rexml/document']]
		OPTIONS = [:name, :elements, :attributes, :attach, :attach_elements, :attach_attributes, :compact,
							:depth, :before_close, :each_before_close, :delineate_with_hash, :as_name, :initialize
							]
		DEFAULTS = [:default_class, :backend, :text_label, :tag_translation, :shared_instance_var, :templates, :template_prefix]
		

		class << self
			attr_accessor *DEFAULTS
		end
	
		(@default_class = Hash) unless defined? @default_class
		
		# Use :libxml, :nokogiri, :ox, :rexml, or anything else, if you want it to always default
		# to something other than the fastest backend found.
		# Nil will let the SaxParser decide.
		(@backend = nil) unless defined? @backend
		
		(@text_label = 'text') unless defined? @text_label
		
		(@tag_translation = [/\-/, '_']) unless defined? @tag_translation
		
		(@shared_instance_var = 'attributes') unless defined? @shared_instance_var		
			
		(@templates = {}) unless defined? @templates
		
		def self.parse(*args)
			Handler.build(*args)
		end

		# Installs attribute accessors for defaults
		def self.install_defaults(klass)
			klass.extend Forwardable		    
	    klass.def_delegators SaxParser, *DEFAULTS
			class << klass
				extend Forwardable
				def_delegators SaxParser, *DEFAULTS
			end		
		end


		
		class Cursor
		
		    attr_accessor :model, :object, :tag, :parent, :top, :stack, :newtag
		    
				SaxParser.install_defaults(self)
		    
		    # Main get-constant method
		    def self.get_constant(klass)
		    	#puts "Getting constant '#{klass.to_s}'"
		    	return default_class if klass.to_s == ''
		    	#return klass unless klass.is_a?(String) || klass.is_a?(Symbol)
		    	return klass if klass.is_a? Class
		    	klass = klass.to_s
		    	
		    	# Added to evaluate fully-qualified class names
		    	return eval(klass.to_s) if klass.to_s && klass.to_s[/::/]
		    	
		    	# TODO: This can surely be cleaned up.
		    	case
		    		# The 2nd condition as added to debug getting 'Array'. Try to get rid of it, extra computing!
			    	when const_defined?(klass) || const_get(klass); const_get(klass)
			  	else
			  		puts "Could not find constant '#{klass.to_s}'"; default_class
			  	end
			  end
		    
		    def initialize(_model, _obj, _tag)
		    	@tag     = _tag
		    	@model   = _model
		    	@object  = _obj       #_obj.is_a?(String) ? get_constant(_obj).new : _obj
		    	self
		    end
		    
		    
		    
		    #####  SAX METHODS  #####
		    
		    # Not sure if this is still used.
			  def receive_attribute(name, value)
			  	#puts "Indiv attrb name '#{name}' value '#{value}' object '#{object.class}' model '#{model.keys}' subm '#{submodel.keys}' tag '#{tag}' newtag '#{newtag}'"
			  	assign_attributes({name=>value}, object, model, model)
			  rescue
			  	puts "Error: could not assign attribute '#{name.to_s}' to element '#{self.tag.to_s}': #{$!}"
			  end
		        
		    def receive_start_element(_tag, _attributes)		
		    	#puts "receive_start_element: _tag '#{_tag}', current object '#{object.class}', cursor_submodel '#{submodel.to_yaml}'."
		    	#puts ['START', _tag, object.class, model]
		    	# Set newtag for other methods to use during the start_el run.
					@newtag = _tag
					
		    	# Acquire submodel definition.
		      subm = model_elements?(@newtag) || default_class.new
		      
		    	if attachment_prefs(model, subm, 'element')=='none'
		    		#puts "Assigning attributes for attach:none on #{newtag}"
		    		assign_attributes(_attributes, object, model, subm)
		    		return
		    	end		      
		      
		      # Create new element.
		      const = get_constant(subm['class'])
		      # Needs to be duped !!!
		      init = initialize?(subm) ? initialize?(subm).dup : []
		      #puts init.to_yaml
		      init[0] ||= :allocate
		      init[1] = eval(init[1].to_s)
		      #puts "Current object: #{eval('object').class}"
		      #puts "Creating new element '#{const}' with '#{init[0]}' and '#{init[1].class}'"
		      new_element = const.send(*init.compact)
		      #puts "Created new element of class '#{new_element.class}' for _tag '#{tag}'."
		      
		      # Assign attributes to new element.
		      assign_attributes(_attributes, new_element, subm, subm)

					# Attach new element to cursor _object
					attach_new_object(object, new_element, newtag, model, subm, 'element')
		  		
		  		returntag = newtag
		  		self.newtag = nil
		      return Cursor.new(subm, new_element, returntag)
		    end # start_el
		
		    def receive_end_element(_tag)
		    	puts ["END_ELEMENT", _tag, object.class.name, before_close?]
	      	begin
		      	# if _tag == self.tag
							# End_element_callback
			      	if before_close?.is_a? Symbol
			      		object.send before_close?, self
			      	elsif before_close?.is_a?(String)
			      		object.send :eval, before_close?
			      	end
							# 	# TODO: This is for hashes with array as value. It may be ilogical in this context. Is it needed?
							# 	if each_before_close? && object.respond_to?('each')
							# 	  object.each{|o| o.send(each_before_close?.to_s, object)}
							#   end
						# end
	
						if _tag == self.tag
		      		# Data cleaup
							(clean_members {|v| clean_members(v){|v| clean_members(v)}}) if compact? #top.model && top.model['compact']
						end
						
						# return true only if matching tags
						if _tag == self.tag
							return true
						end
		      rescue
		      	puts "Error: end_element tag '#{_tag}' failed: #{$!}"
		      end
		    end



				#####  MERGE METHODS  #####
				
		  	# Assign attributes to element.
				def assign_attributes(_attributes, base_object, base_model, new_model)
		      if _attributes && !_attributes.empty?
		      	prefs_exist = model_attributes?(nil, new_model) || attach_attributes?(base_model) || delineate_with_hash?(base_model)
		      	#puts ['ASSIGN_ATTRIBUTES', base_object.class, base_model, new_model]
						#_attributes.each{|k,v| attach_new_object(base_object, v, k, base_model, model_attributes?(k, new_model), 'attribute')}
						# This is trying to merge element set as a whole, if possible.
						case
							when false && base_object.is_a?(Hash) && !prefs_exist
								#puts "Loading attributes as whole."
								base_object.merge! _attributes
							when false && !prefs_exist
								#puts "Loading attributes as shared on '#{base_object.class}'."
								set_attr_accessor('attributes', _attributes, base_object)
							else
								#puts "Loading attributes individually."
								_attributes.each{|k,v| attach_new_object(base_object, v, k, base_model, model_attributes?(k, new_model), 'attribute')}
						end
						# 	if base_object.is_a?(Hash) && !prefs_exist
						# 			#puts "Loading attributes as whole."
						# 			base_object.merge! _attributes
						# 		else
						# 			#puts "Loading attributes individually."
						# 			_attributes.each{|k,v| attach_new_object(base_object, v, k, base_model, model_attributes?(k, new_model), 'attribute')}
						# 	end
		      end
				end
								
				def attach_new_object(base_object, new_object, name, base_model, new_model, type)
					label = label_or_tag(name, new_model)
					
					prefs = attachment_prefs(base_model, new_model, type)
					# 	prefs = case type
					# 		when 'element'; attach?(new_model) || attach_elements?(base_model)
					# 		when 'attribute'; attach?(new_model) || attach_attributes?(base_model)
					# 	end
					shared_variable_name = nil
					
					if prefs.to_s[0,1] == "_"
						shared_variable_name = prefs.gsub(/^_/, '')
						prefs = "shared"
					end
					
					#puts ['ATTACH_NEW_OBJECT', base_object.class, new_object.class, label, type, prefs, shared_variable_name, create_accessors?(base_model)]
					base_object._attach_object!(new_object, label, delineate_with_hash?(new_model), prefs, type, :default_class=>default_class, :shared_variable_name=>shared_variable_name, :create_accessors=>create_accessors?(base_model))
				end
				
				def attachment_prefs(base_model, new_model, type)
					case type
						when 'element'; attach?(new_model) || attach_elements?(base_model) #|| attach?(top.model) || attach_elements?(top.model)
						when 'attribute'; attach?(new_model) || attach_attributes?(base_model) #|| attach?(top.model) || attach_attributes?(top.model)
					end
				end




		    #####  UTILITY  #####
		
			  def get_constant(klass)
			  	self.class.get_constant(klass)
			  end
			  
			  # Methods for current _model
			  def ivg(name, _object=object); _object.instance_variable_get "@#{name}"; end
			  def ivs(name, value, _object=object); _object.instance_variable_set "@#{name}", value; end
			  def model_elements?(which=nil, _model=model); _model && _model.has_key?('elements') && ((_model['elements'] && which) ? _model['elements'].find{|e| e['name']==which} : _model['elements']) ; end
			  def model_attributes?(which=nil, _model=model); _model && _model.has_key?('attributes') && ((_model['attributes'] && which) ? _model['attributes'].find{|a| a['name']==which} : _model['attributes']) ; end
			  def depth?(_model=model); _model && _model['depth']; end
			  def before_close?(_model=model); _model && _model['before_close']; end
			  def each_before_close?(_model=model); _model && _model['each_before_close']; end
			  def compact?(_model=model); _model && _model['compact']; end
			  def attach?(_model=model); _model && _model['attach']; end
			  def attach_elements?(_model=model); _model && _model['attach_elements']; end
			  def attach_attributes?(_model=model); _model && _model['attach_attributes']; end
			  def delineate_with_hash?(_model=model); _model && _model['delineate_with_hash']; end
			  def as_name?(_model=model); _model && _model['as_name']; end
			  def initialize?(_model=model); _model && _model['initialize']; end
			  def create_accessors?(_model=model); _model && [_model['create_accessors']].flatten.compact; end
			  

			  # Methods for submodel
				def label_or_tag(_tag=newtag, _model=submodel); as_name?(_model) || _tag; end

				
		    def clean_members(obj=object)
					# 	cursor.object = clean_member(cursor.object)
					# 	clean_members(ivg(shared_attribute_var, obj))
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
					# 	obj.instance_variables.each do |var|
					# 		dat = obj.instance_variable_get(var)
					# 		obj.instance_variable_set(var, clean_member(dat))
					# 		yield(dat) if block_given?
					# 	end
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
						# 	# Probably shouldn't do this on instance-var values. ...Why not?
						# 		if val.instance_variables.size < 1
						# 			nil
						# 		elsif val.instance_variables.size == 1
						# 			val.instance_variable_get(val.instance_variables[0])
						# 		else
						# 			val
						# 		end
					end
	    	end
		
		end # Cursor
		
		
		
		#####  SAX HANDLER  #####
		
		module Handler
		
			attr_accessor :stack, :template
			
			SaxParser.install_defaults(self)

			# Main parsing interface (also aliased at SaxParser.parse)
			def self.build(io, template=nil, initial_object=nil, parser=nil)
				parser = parser || backend
				parser = get_backend(parser)
				#puts "Using backend parser: #{parser}"
			  parser.build(io, template, initial_object)
		  end
		  
		  def self.included(base)
		  	# Add a .build method to the custom handler class, when the generic Handler module is included.
		    def base.build(io, template=nil, initial_object=nil)
		  		handler = new(template, initial_object)
		  		handler.run_parser(io)
		  		handler
		  	end
		  end # self.included
		  
		  # Takes backend symbol and returns custom Handler class for specified backend.
		  def self.get_backend(parser=nil)
				(parser = decide_backend) unless parser
				if parser.is_a?(String) || parser.is_a?(Symbol)
					parser_proc = PARSERS[parser.to_sym]
					parser_proc.call unless parser_proc.nil? || const_defined?((parser.to_s.capitalize + 'Handler').to_sym)
					SaxParser.const_get(parser.to_s.capitalize + "Handler")
				end
			rescue
				raise "Could not load the backend parser '#{parser}': #{$!}"
		  end
		  
		  # Finds a loadable backend and returns its symbol.
		  def self.decide_backend
		  	BACKENDS.find{|b| !Gem::Specification::find_all_by_name(b[1]).empty?}[0]
		  rescue
		  	raise "The xml parser could not find a loadable backend gem: #{$!}"
		  end
		  
		  def initialize(_template=nil, initial_object=nil)
		  	initial_object = case
		  		when initial_object.nil?; default_class.new
		  		when initial_object.is_a?(Class); initial_object.new
		  		when initial_object.is_a?(String) || initial_object.is_a?(Symbol); SaxParser.get_constant(initial_object).new
		  		else initial_object
		  	end
		  	#initial_object = initial_object || default_class.new || {}
		  	@stack = []
		  	@template = get_template(_template)
		  	@tag_translation = tag_translation
		  	#(@template = @template.values[0]) if @template.size == 1
		  	#y @template
		  	init_element_buffer
		    set_cursor Cursor.new(@template, initial_object, 'top')
		  end
		  
		  # Takes string, symbol, hash, and returns a (possibly cached) parsing template.
		  # String can be a file name, yaml, xml.
		  # Symbol is a name of a template stored in SaxParser@templates (you would set the templates when your app loads).
		  # Templates stored in the SaxParser@templates var can be strings of code, file specs, or hashes.
			def get_template(name)
				dat = templates[name]
				if dat
					rslt = load_template(dat)
				else
					rslt = load_template(name)
				end
				(templates[name] = rslt) #unless dat == rslt
			end
			
			# Does the heavy-lifting of template retrieval.
			def load_template(dat)
				prefix = defined?(template_prefix) ? template_prefix : ''
		  	rslt = case
		  		when dat.is_a?(Hash); dat
		  		when dat.to_s[/\.y.?ml$/i]; (YAML.load_file(File.join(*[prefix, dat].compact)))
		  		# This line might cause an infinite loop.
		  		when dat.to_s[/\.xml$/i]; self.class.build(File.join(*[prefix, dat].compact), nil, {'compact'=>true})
		  		when dat.to_s[/^<.*>/i]; "Convert from xml to Hash - under construction"
		  		when dat.is_a?(String); YAML.load dat
		  		else default_class.new
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
				return name unless @tag_translation.is_a?(Array)
				name.to_s.gsub(*@tag_translation)
			end
			
			def init_element_buffer
		    @element_buffer = {:tag=>nil, :attributes=>default_class.new, :text=>''}
			end
			
			def send_element_buffer
		    if element_buffer?
		    	(@element_buffer[:attributes][text_label] = @element_buffer[:text]) if @element_buffer[:text].to_s[/[^\s]/]
          set_cursor cursor.receive_start_element(@element_buffer[:tag], @element_buffer[:attributes])
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
				send_element_buffer if element_buffer?
				if attributes
					# This crazy thing transforms attribute keys to underscore (or whatever).
					#attributes = default_class[*attributes.collect{|k,v| [transform(k),v] }.flatten]
					attributes = {}.tap {|hash| attributes.each {|k, v| hash[transform(k)] = v}}
				end
				@element_buffer.merge!({:tag=>tag, :attributes => attributes || default_class.new})
			end
			
			# Add attribute to existing element.
			def _attribute(name, value, *args)
				#puts "Receiving attribute '#{name}' with value '#{value}'"
				name = transform name
				@element_buffer[:attributes].merge!({name=>value})
			end
			
			# Add 'content' attribute to existing element.
			def _text(value, *args)
				#puts "Receiving text '#{value}'"
				return unless value.to_s[/[^\s]/]
			  @element_buffer[:text] << value
			end
			
			# Close out an existing element.
			def _end_element(tag, *args)
				tag = transform tag
				#puts "Receiving end_element '#{tag}'"
	      send_element_buffer
	      cursor.receive_end_element(tag) and dump_cursor
			end
		  
		end # Handler
		
		
		
		#####  SAX PARSER BACKEND HANDLERS  #####
		
		PARSERS[:libxml] = proc do
			require 'libxml'
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
		end
		
		PARSERS[:nokogiri] = proc do
			require 'nokogiri'
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
		end
		
		PARSERS[:ox] = proc do
			require 'ox'
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
		end

		PARSERS[:rexml] = proc do
			require 'rexml/document'
			require 'rexml/streamlistener'
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
		end
		

	end # SaxParser
end # Rfm




#####  CORE PATCHES  #####

class Object

	# Master method to attach any object to this object.
	def _attach_object!(obj, *args) # name/label, collision-delimiter, attachment-prefs, type, *options: <options>
		default_options = {
			:shared_variable_name => 'attributes',
			:default_class => Hash,
			:create_accessors => [] #:all, :private, :shared, :hash
		}
		options = default_options.merge(args.last.is_a?(Hash) ? args.pop : {}){|key, old, new| new || old}
		name = (args[0] || options[:name])
		delimiter = (args[1] || options[:delimiter])
		prefs = (args[2] || options[:prefs])
		type = (args[3] || options[:type])
		#puts ['_ATTACH_OBJECT', self.class, obj.class, name, type, prefs, options[:shared_variable_name], options[:create_accessors]]
		case
		when prefs=='none' || prefs=='cursor'; nil
		when name
			self._merge_object!(obj, name, delimiter, prefs, type, options)
		else
			self._merge_object!(obj, 'unknown_name', delimiter, prefs, type, options)
		end
	end
	
	# Master method to merge any object with this object
	def _merge_object!(obj, name, delimiter, prefs, type, options={})
		if prefs=='instance'
			_merge_instance!(obj, name, delimiter, prefs, type, options)
		else
			_merge_shared!(obj, name, delimiter, prefs, type, options)
		end
	end
	
	# Merge a named object with the shared instance variable of self.
	def _merge_shared!(obj, name, delimiter, prefs, type, options={})
		shared_var = instance_variable_get("@#{options[:shared_variable_name]}") || instance_variable_set("@#{options[:shared_variable_name]}", options[:default_class].new)
		#puts "Merge shared: self '#{self.class}' obj '#{obj.class}' name '#{name}' delimiter '#{delimiter}' type '#{type}' shared_var '#{options[:shared_variable_name]} - #{shared_var.class}'"
		#eval("@#{options[:shared_variable_name]} ||= #{options[:default_class].new}")._merge_object!(obj, name, delimiter, nil, type, options)
		shared_var._merge_object!(obj, name, delimiter, nil, type, options)
		if (options[:create_accessors] & [:all, :shared]).size > 0
			meta = (class << self; self; end)
			meta.send(:attr_reader, options[:shared_variable_name])
		end
	end
	
	# Merge a named object with the specified instance variable of self.
	def _merge_instance!(obj, name, delimiter, prefs, type, options={})
		if instance_variable_get("@#{name}") || delimiter
			if delimiter
				delimit_name = obj._get_attribute(delimiter, options[:shared_variable_name]).downcase
				instance_variable_set("@#{name}", instance_variable_get("@#{name}") || options[:default_class].new)[delimit_name]=obj
			else
				instance_variable_set("@#{name}", [instance_variable_get("@#{name}")].flatten << obj)
			end
		else
			instance_variable_set("@#{name}", obj)
		end
		if (options[:create_accessors] & [:all, :private]).size > 0
			meta = (class << self; self; end)
			meta.send(:attr_reader, name.downcase.gsub(/\s/,'_'))
		end
	end
	
	# Get an instance variable, a member of a shared instance variable, or a hash value of self.
  def _get_attribute(name, shared=nil, options={})
  	return unless name
  	(shared = options[:shared_variable_name]) unless shared
		
		rslt = case
		when self.is_a?(Hash); self[name]
		when (var= instance_variable_get("@#{shared}")); var[name]
		else instance_variable_get("@#{name}")
		end
		
		#puts "Object#_get_attribute: name '#{name}' shared '#{shared}' options '#{options}' rslt '#{rslt}'"
		rslt
  end

end # Object

class Array
	def _merge_object!(obj, name, delimiter, prefs, type, options={})
		case
		when prefs=='shared' || type == 'attribute'; _merge_shared!(obj, name, delimiter, prefs, type, options)
		when prefs=='instance'; _merge_instance!(obj, name, delimiter, prefs, type, options)
		else self << obj
		end
	end
end # Array

class Hash
	def _merge_object!(obj, name, delimiter, prefs, type, options={})
		#puts "hash._merge_object name '#{name}' delimiter '#{delimiter}' prefs '#{prefs}'"
		case
		when prefs=='shared'
			_merge_shared!(obj, name, delimiter, prefs, type, options)
		when prefs=='instance'
			_merge_instance!(obj, name, delimiter, prefs, type, options)
		when (self[name] || delimiter)
			if delimiter
				delimit_name =  obj._get_attribute(delimiter, options[:shared_variable_name]).downcase
				#puts "merging delimited object with hash: self '#{self.class}' obj '#{obj.class}' name '#{name}' delim '#{delimiter}' delim_name '#{delimit_name}' options '#{options}'"
				self[name] ||= options[:default_class].new
				self[name][delimit_name]=obj
			else
				self[name] = [self[name]].flatten
				self[name] << obj
			end
		else
			self[name] = obj
		end
		if (options[:create_accessors] & [:all, :hash]).size > 0
			meta = (class << self; self; end)
			meta.send(:define_method, name.downcase.gsub(/\s/,'_')) do
				self[name.downcase.gsub(/\s/,'_')] = obj
			end
		end
	end
end # Hash


