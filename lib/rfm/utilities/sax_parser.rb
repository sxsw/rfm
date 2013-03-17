#####  A declarative SAX parser, written by William Richardson  #####
#
# Use:
#   irb -rubygems -I./  -r  lib/rfm/utilities/sax_parser.rb
#   r = Rfm::SaxParser::Handler.build(Rfm::SaxParser::DAT[:fmp], 'lib/rfm/sax/fmresultset.yml', Rfm::SaxParser::OxFmpSax)
#   r = OxFmpSax.build(Rfm::SaxParser::DAT[:fmp], 'local_testing/sax_parser.yml')
#   r = Rfm::SaxParser::Handler.build(Rfm::SaxParser::DAT[:fm], 'lib/rfm/sax/fmresultset.yml', Rfm::SaxParser::RexmlStream)
#
#####

#gem 'ox', '1.8.5'
require 'stringio'
require 'ox'
require 'yaml'
require 'rexml/parsers/streamparser'
require 'rexml/streamlistener'
require 'rexml/document'
require 'libxml'

# TODO: Move test data & user models to spec folder and local_testing.
# TODO: Move attribute/text buffer from sax handler to cursor.
# TODO: Create special file in local_testing for experimentation & testing - will have user models, grammar-yml, calling methods.
# TODO: Add option to 'compact' unnecessary or empty elements/attributes - maybe - should this should be handled at Model level?
# TODO: Add nokogiri, libxml-ruby, rexml interfaces.
# TODO: Separate all attribute options into attributes: hash, similar to elements: hash.
# TODO: Handle multiple 'text' callbacks for a single element.
# TODO: Add options for text handling (what to name, where to put).
# TODO: Allow nil as yml document - parsing will be generic. But throw error if given yml doc can't open.


module Rfm
	module SaxParser
	
		class Cursor
		
		    attr_accessor :model, :obj, :tag, :parent, :top, :stack, :current_tag
		    
		    def self.constantize(klass)
			  	SaxParser.const_get(klass.to_s)
		  	rescue
		  		#puts "Error: cound not constantize '#{klass.to_s}'" unless klass.to_s == ''
			  	nil
			  end
		    
		    def initialize(model, obj, tag)
		    	@tag   = tag
		    	@model = model
		    	@obj   = obj.is_a?(String) ? constantize(obj).new : obj
		    	self
		    end
		    
		    
		    
		    #####  SAX METHODS  #####
		    
		    def attribute(name,value); (obj[name]=value) rescue nil end
		        
		    def start_el(tag, attributes)		
		    	return if (model['ignore_unknown'] && !model['elements'][tag])
		
		    	# Acquire submodel definition.
		      sub = submodel(tag)
		      
		      original_tag = tag
		      (tag = element_as) if element_as		      
		      
		      # Create new element.
		      new_element = (constantize((sub['class']).to_s) || Hash).new
		      #puts "Created new element of class '#{new_element.class}' for tag '#{tag}'."
		      
		      # Assign attributes to new element.
		      if !attributes.empty?
		        if new_element.is_a?(Hash) and !hide_attributes
		          new_element.merge!(attributes)
			      elsif individual_attributes
			        attributes.each{|k, v| set_element_accessor(k, v, new_element)}
		        else
			        set_element_accessor 'att', attributes, new_element
			      end
		      end
		      
		      # Attach new object to current object.
		      unless sub['hide']
		  			if as_attribute
							merge_with_attributes(as_attribute, new_element)
		    		elsif obj.is_a?(Hash)
	  					merge_with_hash(tag, new_element)
		    		elsif obj.is_a? Array
							merge_with_array(tag, new_element)
		    		else
		  				merge_with_attributes(tag, new_element)
		    		end
		      end
		  		
		      return Cursor.new(sub, new_element, original_tag)
		    end
		
		    def end_el(name)
		    	# DONE: filter-out untracked cursors
		    	#puts self.tag
		      if name == self.tag
		      	begin
		      		#puts "RUNNING: end_el - eval for element - #{name}:#{model['before_close']}"
			      	# This is for arrays
			      	obj.send(model['before_close'].to_s, self) if model['before_close']
			      	# This is for hashes with array as value. It may be ilogical in this context. Is it needed?
			      	if obj.respond_to?('each') && model['each_before_close']
			      	  obj.each{|o| o.send(model['each_before_close'].to_s, obj)}
		      	  end
			      rescue
			      	puts "Error: #{$!}"
			      end
		        return true
		      end
		    end
		    
		    
		    
		    
		    #####  UTILITY  #####
		
			  def constantize(klass)
			  	self.class.constantize(klass)
			  end
			  
			  def ivg(name, object=obj); object.instance_variable_get "@#{name}" end
			  def ivs(name, value, object=obj); object.instance_variable_set "@#{name}", data end
		    
				def get_submodel(name)
					model['elements'][name] rescue nil
				end
				
				def default_submodel
					if model['depth'].to_i > 0
						{'elements' => model['elements'], 'depth'=>(model['depth'].to_i - 1)}
					else
						{}
					end
				end
				
				def submodel(tag=current_tag); self.current_tag = tag; get_submodel(tag) || default_submodel; end
			  def individual_attributes; submodel['individual_attributes']; end    
			  def hide_attributes; submodel['hide_attributes']; end
		    def as_attribute; submodel['as_attribute']; end
		  	def delineate_with_hash; submodel['delineate_with_hash']; end
		  	def element_as; submodel['as']; end
		    
		    
		    def resolve_conflicts(cur, new_element)
		  	  if delineate_with_hash
		  	    current_key = get_attribute(delineate_with_hash, cur)
		  	    new_key = get_attribute(delineate_with_hash, new_element)
		  	    #puts "Current-key '#{current_key}', New-key '#{new_key}'"
		  	    if !current_key.to_s.empty? and !new_key.to_s.empty?
		  	    	Hash[current_key => cur].merge(new_key => new_element)
		  	    else
		  	    	cur.merge(new_key => new_element)
		  	    end	  
		  	  else
		  	  	[*cur] << new_element #Array[cur].flatten.compact << new_element
		    	end
		    end
		    
		    def get_attribute(name, obj=obj)
		      return obj.att[name] rescue nil
		      return ivg(name, obj) rescue nil
		      return obj[name] rescue nil
		    end
		    
		    def merge_with_attributes(name, element)
  			  if ivg(as_attribute)
					  set_element_accessor(name, resolve_conflicts(ivg(name), element))
					else
					  set_element_accessor(as_attribute, element)
				  end
		    end
		    
		    def merge_with_hash(name, element)
    			if obj.has_key? name
  					obj[name] = resolve_conflicts(obj[name], element)
  			  else			
  	  			obj[name] = element
    			end
		    end
		    
		    def merge_with_array(name, element)
					if obj.size > 0
						obj.replace resolve_conflicts(obj, element)
					else
  	  			obj << element
	  			end
		    end
		    
		    def set_element_accessor(name, element, obj=obj)
					create_accessor(name, obj)
					obj.send "#{name}=", element
				end
				
				def create_accessor(tag, obj=obj)
					obj.class.class_eval do
						attr_accessor "#{tag}"
					end
				end
		
		end # Cursor
		
		
		
		#####  SAX HANDLER(S)  #####
		
		module Handler
		
			attr_accessor :stack, :grammar
			
			def self.build(io, grammar, parser)
			  (eval(parser.to_s)).build(io, grammar)
		  end
		  
		  def self.included(base)
		
		    def base.build(io, grammar, initial_object=Hash.new)
		  		handler = new(grammar, initial_object)
		  		handler.run_parser(io)
		  		handler.stack[0].obj
		  	end
		  	
		  	def base.handler
		  		@handler
		  	end
		  end
		  
		  def initialize(grammar, initial_object=Hash.new)
		  	@stack = []
		  	@grammar = YAML.load_file(grammar)
		  	# Not necessary - for testing only
		  		self.class.instance_variable_set :@handler, self
		  	init_element_buffer
		    set_cursor Cursor.new(@grammar, initial_object, 'TOP')
		  end
		  
			def cursor
				stack.last
			end
			
			def set_cursor(args) # cursor-object
				if args.is_a? Cursor
					stack.push(args)
					cursor.parent = stack[-2]
					cursor.top = stack[0]
					cursor.stack = stack
				end
				cursor
			end
			
			def dump_cursor
				stack.pop
			end
			
		  def init_element_buffer
		  	@element_buffer = {:name=>nil, :attr=>{}}
		  end
		  
		  def send_element_buffer
		  	if element_buffer?
			  	set_cursor cursor.start_el(@element_buffer[:name], @element_buffer[:attr])
			  	init_element_buffer
			  end
			end
			
			def element_buffer?
				@element_buffer[:name] && !@element_buffer[:name].empty?
			end
		
		  # Add a node to an existing element.
			def _start_element(name, attributes=nil)
				send_element_buffer
				if attributes.nil?
					@element_buffer = {:name=>name, :attr=>{}}
				else
					set_cursor cursor.start_el(name, attributes)
				end
			end
			
			# Add attribute to existing element.
			def _attribute(name, value)
				@element_buffer[:attr].merge!({name=>value})
		    #cursor.attribute(name,value)
			end
			
			# Add 'content' attribute to existing element.
			def _text(value)
				if !element_buffer?
					cursor.attribute('text', value)
				else
					# Disabling this should prevent text in parents with children, but it doesn't seem to work with REXML streaming.
					@element_buffer[:attr].merge!({'text'=>value})
					send_element_buffer
				end
			end
			
			# Close out an existing element.
			def _end_element(value)
				send_element_buffer
				cursor.end_el(value) and dump_cursor
			end
		  
		end # Handler
		
		
		
		#####  SAX PARSER BACKENDS  #####
		
		class OxFmpSax < ::Ox::Sax
		
		  include Handler
		
		  def run_parser(io)
				case
				when (io.is_a?(File) or io.is_a?(StringIO)); Ox.sax_parse self, io
				when io[/^</]; StringIO.open(io){|f| Ox.sax_parse self, f}
				else File.open(io){|f| Ox.sax_parse self, f}
				end
			end
			
		  def start_element(name); _start_element(name.to_s.gsub(/\-/, '_'));        	end
		  def end_element(name);   _end_element(name.to_s.gsub(/\-/, '_'));          end
		  def attr(name, value);   _attribute(name.to_s.gsub(/\-/, '_'), value);     end
		  def text(value);         _text(value);                              				end
		  
		end # OxFmpSax


		class RexmlStream
		
			include REXML::StreamListener
		
		  include Handler
		
		  def run_parser(io)
		  	parser = REXML::Document
				case
				when (io.is_a?(File) or io.is_a?(StringIO)); parser.parse_stream(io, self)
				when io[/^</]; StringIO.open(io){|f| parser.parse_stream(f, self)}
				else File.open(io){|f| parser.parse_stream(f, self)}
				end
			end
			
		  def tag_start(name, attributes); _start_element(name.to_s.gsub(/\-/, '_'), attributes);        	end
		  def tag_end(name);   _end_element(name.to_s.gsub(/\-/, '_'));          end
		  def text(value);         _text(value);                              				end
		  
		end # RexmlStream
		
		
		class LibXmlSax
			include LibXML
			include XML::SaxParser::Callbacks
		  include Handler
		
		  def run_parser(io)
				# 				parser = XML::SaxParser.io(io)
				# 				parser.callbacks = self
				# 				parser.parse		  
		  
				parser = case
					when (io.is_a?(File) or io.is_a?(StringIO)); XML::SaxParser.io(io)
					when io[/^</]; XML::SaxParser.io(StringIO.new(io))
					else XML::SaxParser.io(File.new(io))
				end
				parser.callbacks = self
				parser.parse	
			end
			
		  def on_start_element_ns(name, attributes, prefix, uri, namespaces); _start_element(name.to_s.gsub(/\-/, '_'), attributes);        	end
		  def on_end_element_ns(name, prefix, uri);   _end_element(name.to_s.gsub(/\-/, '_'));          end
		  def on_characters(value);         _text(value);                              				end
		  
		end # LibxmlSax	
		
		
		
		#####  USER MODELS  #####
		
		class FmResultset < Hash
		end
		
		class Datasource < Hash
		end
		
		class Metadata < Array
		end
		
		class Resultset < Array
			def attach_parent_objects(cursor)
				elements = cursor.parent.obj
				elements.each{|k, v| cursor.set_element_accessor(k, v) unless k == 'resultset'}
				cursor.stack[0] = cursor
			end
		end
		
		class Record < Hash
		end
		
		class Field < Hash
			def build_record_data(cursor)
				#puts "RUNNING Field#build_field_data on record_id:#{cursor.obj['name']}"
				cursor.parent.obj.merge!(cursor.obj['name'] => (cursor.obj['data']['text'] rescue ''))
			end
		end
		
		class RelatedSet < Array
		end
		
		
		
		
		#####  DATA  #####
		DAT = {
			:fm => 'local_testing/resultset.xml',
			:fmp => 'local_testing/resultset_with_portals.xml',
			:xml => 'local_testing/data_fmpxmlresult.xml',
			:xmp => 'local_testing/data_with_portals_fmpxmlresult.xml',
			:lay => 'local_testing/layout.xml',
			:xmd => 'local_testing/db_fmpxmlresult.xml',
			:fmb => 'local_testing/resultset_with_bad_data.xml',
			:sp => 'local_testing/SplashLayout.xml',
			
			:str => StringIO.new(%{
			<top name="top01">
				<middle name="middle01" />
			  <middle name="middle02">
			    <bottom name="bottom01">bottom-text</bottom>
			  </middle>
			  <middle name="middle03">middle03-text</middle>
			</top>
			})
		}

	end # SaxParser
end # Rfm