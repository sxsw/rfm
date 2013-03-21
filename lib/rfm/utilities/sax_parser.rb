#####  A declarative SAX parser, written by William Richardson  #####
#
# Use:
#   irb -rubygems -I./  -r  lib/rfm/utilities/sax_parser.rb
#   r = Rfm::SaxParser::Handler.build(Rfm::SaxParser::DAT[:fmp], Rfm::SaxParser::OxFmpSax, 'lib/rfm/sax/fmresultset.yml')
#   r = Rfm::SaxParser::OxFmpSax.build(Rfm::SaxParser::DAT[:fmp], 'local_testing/sax_parser.yml')
#   r = Rfm::SaxParser::Handler.build(Rfm::SaxParser::DAT[:fm], Rfm::SaxParser::RexmlStream, 'lib/rfm/sax/fmresultset.yml')
#
# Sandbox:
#   irb -rubygems -I./  -r  local_testing/sax_parser_sandbox.rb
#   > Sandbox.parse
#
#####

#gem 'ox', '1.8.5'
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
# TODO: Separate all attribute options in yml into 'attributes:' hash, similar to 'elements:' hash.
# TODO: Handle multiple 'text' callbacks for a single element.
# TODO: Add options for text handling (what to name, where to put).
# TODO: Fill in other configuration options in yml


module Rfm
	module SaxParser
	
		(DEFAULT_CLASS = Hash) unless defined? DEFAULT_CLASS
		
		# Use :libxml, or anything else, if you want it to always default
		# to something other than the fastest backend found.
		DEFAULT_BACKEND = nil
		
		BACKENDS = [[:ox, 'ox'], [:libxml, 'libxml-ruby'], [:nokogiri, 'nokogiri'], [:rexml, 'rexml/document']]

		
		class Cursor
		
		    attr_accessor :_model, :_obj, :_tag, :_parent, :_top, :_stack, :_new_tag
		    
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
		    	case
			    	when const_defined?(klass); const_get(klass)
			    	when self.ancestors[0].const_defined?(klass); self.ancestors[0].const_get(klass)
			    	when SaxParser.const_defined?(klass); SaxParser.const_get(klass)
			    	when Object.const_defined?(klass); Object.const_get(klass)
				  	when Module.const_defined?(klass); Module.const_get(klass)
				  	else puts "Could not find constant '#{klass.to_s}'"; DEFAULT_CLASS
			  	end
			  end
		    
		    def initialize(model, obj, tag)
		    	@_tag   = tag
		    	@_model = model
		    	@_obj   = obj.is_a?(String) ? get_constant(obj).new : obj
		    	self
		    end
		    
		    
		    
		    #####  SAX METHODS  #####
		    
		    def attribute(name, value)
		    	return if (_model['ignore_unknown'] && !(_model['attributes'] && _model['attributes'][name]))
		    	assign_attributes({name=>value})
		    rescue
		    	puts "Error: could not assign attribute '#{name.to_s}' to element '#{self._tag.to_s}': #{$!}"
		    end
		        
		    def start_el(tag, attributes)		
		    	return if (_model['ignore_unknown'] && !_model['elements'][tag])
		    	
		    	# Set _new_tag for other methods to use during the start_el run.
		    	self._new_tag = tag
		
		    	# Acquire submodel definition.
		      subm = submodel      
		      
		      # Create new element.
		      #new_element = (get_constant((subm['class']).to_s) || Hash).new
		      new_element = get_constant(subm['class']).new
		      #puts "Created new element of class '#{new_element.class}' for tag '#{_tag}'."
		      
		      # Assign attributes to new element.
		      assign_attributes attributes, new_element, subm

					# Attach new element to cursor object
					attach_new_object_master(subm, new_element)
		  		
		  		return_tag = _new_tag
		  		self._new_tag = nil
		      return Cursor.new(subm, new_element, return_tag)
		    end # start_el
		
		    def end_el(tag)
		      if tag == self._tag
		      	begin
		      		# Data cleaup
							(clean_members {|v| clean_members(v){|v| clean_members(v)}}) if _top._model && _top._model[:compact]
			      	# This is for arrays
			      	_obj.send(_model['before_close'].to_s, self) if _model['before_close']
			      	# TODO: This is for hashes with array as value. It may be ilogical in this context. Is it needed?
			      	if _model['each_before_close'] && _obj.respond_to?('each')
			      	  _obj.each{|o| o.send(_model['each_before_close'].to_s, _obj)}
		      	  end
			      rescue
			      	puts "Error ending element tagged '#{tag}': #{$!}"
			      end
		        return true
		      end
		    end


		    #####  UTILITY  #####
		
			  def get_constant(klass)
			  	self.class.get_constant(klass)
			  end
			  
			  def ivg(name, object=_obj); object.instance_variable_get "@#{name}" end
			  def ivs(name, value, object=_obj); object.instance_variable_set "@#{name}", value end
			  
				def submodel(tag=_new_tag); get_submodel(tag) || default_submodel; end
			  def individual_attributes(model=submodel); model['individual_attributes']; end    
			  def hide_attributes(model=submodel); model['hide_attributes']; end
		    def as_attribute(model=submodel); model['as_attribute']; end
		  	def delineate_with_hash(model=submodel); model['delineate_with_hash']; end
		  	def as_label(model=submodel); model['as_label']; end
		  	def label_or_tag; as_label(submodel) || _new_tag; end
		  	
				def get_submodel(name)
					_model['elements'] && _model['elements'][name]
				end
				
				def default_submodel
					#puts "Using default submodel"
					if _model['depth'].to_i > 0
						{'elements' => _model['elements'], 'depth'=>(_model['depth'].to_i - 1)}
					else
						DEFAULT_CLASS.new
					end
				end
		  	
	      # Attach new object to current object.
	      def attach_new_object_master(subm, new_element)
	      	#puts "Attaching new object '#{_new_tag}:#{new_element.class}' to '#{_tag}:#{subm.class}'"
		      unless subm['hide']
		  			if as_attribute
							merge_with_attributes(as_attribute, new_element)
		    		elsif _obj.is_a?(Hash)
	  					merge_with_hash(label_or_tag, new_element)
		    		elsif _obj.is_a? Array
							merge_with_array(label_or_tag, new_element)
		    		else
		  				merge_with_attributes(label_or_tag, new_element)
		    		end
		      end
		    end
		  	
		  	# Assign attributes to element.
				def assign_attributes(attributes=nil, element=_obj, model=_model)
		      if attributes && !attributes.empty?
		      	(attributes = DEFAULT_CLASS[attributes]) if attributes.is_a? Array # For nokogiri attributes-as-array
		      	#puts "Assigning attributes: #{attributes.to_a.join(':')}" if attributes.has_key?('text')
		        if element.is_a?(Hash) and !hide_attributes(model)
		        	#puts "Assigning element attributes for '#{element.class}' #{attributes.to_a.join(':')}"
		          element.merge!(attributes)
			      elsif individual_attributes(model)
			      	#puts "Assigning individual attributes for '#{element.class}' #{attributes.to_a.join(':')}"
			        attributes.each{|k, v| set_attr_accessor(k, v, element)}
		        else
		        	#puts "Assigning @att attributes for '#{element.class}' #{attributes.to_a.join(':')}"
			        set_attr_accessor 'att', attributes, element
			      end
		      end
				end
		    
		    def merge_elements(current_element, new_element)
		    	# delineate_with_hash is the attribute name to match on.
		    	# current_key/new_key is the actual value of the match element.
		    	# current_key/new_key is then used as a hash key to contain elements that match on the delineate_with_hash attribute.
		    	#puts "merge_elements with tags '#{self._tag}/#{label_or_tag}' current_el '#{current_element.class}' and new_el '#{new_element.class}'."
	  	  	begin
		  	    current_key = get_attribute(delineate_with_hash, current_element)
		  	    new_key = get_attribute(delineate_with_hash, new_element)
		  	    #puts "Current-key '#{current_key}', New-key '#{new_key}'"
		  	    
		  	    key_state = case
		  	    	when !current_key.to_s.empty? && current_key == new_key; 5
		  	    	when !current_key.to_s.empty? && !new_key.to_s.empty?; 4
		  	    	when current_key.to_s.empty? && new_key.to_s.empty?; 3
		  	    	when !current_key.to_s.empty?; 2
		  	    	when !new_key.to_s.empty?; 1
		  	    	else 0
		  	    end
		  	  
		  	  	case key_state
			  	  	when 5; {current_key => [current_element, new_element]}
			  	  	when 4; {current_key => current_element, new_key => new_element}
			  	  	when 3; [current_element, new_element].flatten
			  	  	when 2; {current_key => ([*current_element] << new_element)}
			  	  	when 1; current_element.merge(new_key=>new_element)
			  	  	else    [current_element, new_element].flatten
		  	  	end
		  	  	
	  	    rescue
	  	    	puts "Error: could not merge with hash: #{$!}"
	  	    	([*current_element] << new_element) if current_element.is_a?(Array)
	  	    end
		    end # merge_elements
		    
		    def get_attribute(name, obj=_obj)
		    	return unless name
		    	case
		    		when (obj.respond_to?(:att) && obj.att); obj.att[name]
		    		when (r= ivg(name, obj)); r
		    		else obj[name]
		    	end
		    end
		    
		    def merge_with_attributes(name, element)
  			  if ivg(name)
  			  #if get_attribute(name)
					  #set_attr_accessor(name, merge_elements(ivg(name), element))
					  ivs(name, merge_elements(ivg(name), element))
					else
					  set_attr_accessor(name, element)
				  end
		    end
		    
		    def merge_with_hash(name, element)
    			if _obj[name] #_obj.has_key? name
  					_obj[name] = merge_elements(_obj[name], element)
  			  else			
  	  			_obj[name] = element
    			end
		    end
		    
		    # TODO: Does this really need to use merge_elements?
		    def merge_with_array(name, element)
					if _obj.size > 0
						_obj.replace merge_elements(_obj, element)
					else
  	  			_obj << element
	  			end
		    end
		    
		    def set_attr_accessor(name, data, obj=_obj)
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
								
				def create_accessor(tag, obj=_obj)
					#return unless tag && obj
					# 	obj.class.class_eval do
					# 		attr_accessor "#{tag}"
					# 	end unless obj.instance_variables.include?(":@#{tag}")
					obj.class.send :attr_accessor, tag unless obj.instance_variables.include?(":@#{tag}")
				end
				
		    def clean_members(obj=_obj)
	    		if obj.is_a?(Hash)
	    			obj.dup.each do |k,v|
	    				obj[k] = nil if v && v.empty?
	    				(obj[k] = v.values[0]) if v && v.respond_to?(:values) && v.size == 1
	    				yield(v) if block_given?
	    			end
	    		elsif obj.is_a?(Array)
	    			obj.dup.each_with_index do |v,i|
	    				obj[i] = nil if v && v.empty?
	    				(obj[i] = v.values[0]) if v && v.respond_to?(:values) && v.size == 1
	    				yield(v) if block_given?
	    			end
	    		end
	    	end
		
		end # Cursor
		
		
		
		#####  SAX HANDLER  #####
		
		module Handler
		
			attr_accessor :stack, :grammar
			
			def self.build(io, backend=DEFAULT_BACKEND, grammar=nil, initial_object=DEFAULT_CLASS.new)
				backend = decide_backend unless backend
				backend = (backend.is_a?(String) || backend.is_a?(Symbol)) ? SaxParser.const_get(backend.to_s.capitalize + "Handler") : backend
			  backend.build(io, grammar, initial_object)
		  end
		  
		  def self.included(base)
		    def base.build(io, grammar=nil, initial_object= DEFAULT_CLASS.new)
		  		handler = new(grammar, initial_object)
		  		handler.run_parser(io)
		  		#handler.stack[0]._obj
		  		handler
		  	end
		  end # self.included()
		  
		  def self.decide_backend
		  	BACKENDS.find{|b| !Gem::Specification::find_all_by_name(b[1]).empty?}[0]
		  rescue
		  	raise "The xml parser could not find a loadable backend gem: #{$!}"
		  end
		  
		  def initialize(grammar=nil, initial_object= DEFAULT_CLASS.new)
		  	@stack = []
		  	@grammar = case
		  		when grammar.to_s[/\.y.?ml$/i]; (YAML.load_file(grammar))
		  		when grammar.to_s[/^<.*>/]; "Convert from xml to Hash - under construction"
		  		when grammar.is_a?(String); YAML.load grammar
		  		when grammar.is_a?(Hash); grammar
		  		else DEFAULT_CLASS.new
		  	end
		  	init_element_buffer
		    set_cursor Cursor.new(@grammar, initial_object, 'TOP')
		  end
		  
		  def result
		  	stack[0]._obj if stack[0].is_a? Cursor
		  end
		  
			def cursor
				stack.last
			end
			
			def set_cursor(args) # cursor-object
				if args.is_a? Cursor
					stack.push(args)
					cursor._parent = stack[-2]
					cursor._top = stack[0]
					cursor._stack = stack
				end
				cursor
			end
			
			def dump_cursor
				stack.pop
			end
			
			def transform(name)
				name.to_s.gsub(/\-/, '_')
			end
			
			def init_element_buffer
		    @element_buffer = {:tag=>nil, :attr=>DEFAULT_CLASS.new}
			end
			
			def send_element_buffer
		    if element_buffer?
          set_cursor cursor.start_el(@element_buffer[:tag], @element_buffer[:attr])
          init_element_buffer
	      end
	    end
	    
	    def element_buffer?
	      @element_buffer[:tag] && !@element_buffer[:tag].empty?
	    end
		
		  # Add a node to an existing element.
			def _start_element(tag, attributes=nil, *args)
				#puts "Receiving element '#{tag}' with attributes '#{attributes}'"
				tag = transform tag
				send_element_buffer
				if attributes
					# This crazy thing transforms attribute keys to underscore (or whatever).
					attributes = DEFAULT_CLASS[*attributes.collect{|k,v| [transform(k),v] }.flatten]
					set_cursor cursor.start_el(tag, attributes)
				else
				  @element_buffer = {:tag=>tag, :attr => DEFAULT_CLASS.new}
				end
			end
			
			# Add attribute to existing element.
			def _attribute(name, value, *args)
				#puts "Receiving attribute '#{name}' with value '#{value}'"
				name = transform name
		    #cursor.attribute(name,value)
				@element_buffer[:attr].merge!({name=>value})
			end
			
			# Add 'content' attribute to existing element.
			def _text(value, *args)
				#puts "Receiving text '#{value}'"
				return unless value[/[^\s]/]
				if element_buffer?
				  @element_buffer[:attr].merge!({'text'=>value})
				  send_element_buffer
				else
					cursor.attribute('text', value)
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
				when io[/^</]; StringIO.open(io){|f| Ox.sax_parse self, f}
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
			# but don't put them here... put them at the top.
			#require 'rexml/streamlistener'
			#require 'rexml/document'
			include REXML::StreamListener
		  include Handler
		
		  def run_parser(io)
		  	parser = REXML::Document
				case
				when (io.is_a?(File) or io.is_a?(StringIO)); parser.parse_stream(io, self)
				when io && io[/^</]; StringIO.open(io){|f| parser.parse_stream(f, self)}
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

