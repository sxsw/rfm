# From https://github.com/ohler55/ox
# Do: irb -rubygems -r  lib/rfm/utilities/sax_parser.rb
# Do: r = OxFmpSax.build(FM, 'local_testing/sax_parser.yml')
# Do: r = SaxHandler.build(XMP, 'local_testing/sax_parse.yml', OxFmpSax)

#gem 'ox', '1.8.5'
require 'stringio'
require 'ox'
require 'delegate'
require 'yaml'
require 'rfm'


class Cursor

    attr_accessor :model, :obj, :parent, :top, :stack, :current_tag
    
    def self.constantize(klass)
	  	Object.const_get(klass.to_s) rescue nil
	  end
    
    def initialize(model, obj)
    	@model = model
    	@obj   = obj.is_a?(String) ? constantize(obj).new : obj
    	self
    end
    
    
    
    #####  SAX METHODS  #####
    
    def attribute(name,value); (obj[name]=value) rescue nil end
        
    def start_el(tag, attributes)
    	return if (model['ignore_unknown']  && !model['elements'][tag])
    	
    	# Acquire submodel grammar.
      sub = submodel(tag)
      
      # Create new element.
      new_element = (constantize((sub['class']).to_s) || Hash).new
      
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
  			  if ivg(as_attribute)
					  merge_with_attributes(as_attribute, new_element, delineate_on, delineate_with)
					else
					  set_element_accessor(as_attribute, new_element)
				  end
    		elsif obj.is_a?(Hash)
    			if obj.has_key? tag
  					merge_with_hash(tag, new_element, delineate_on, delineate_with)
  			  else			
  	  			obj[tag] = new_element
    			end
    		elsif obj.is_a? Array
					if obj.size > 0
						merge_with_array(tag, new_element, delineate_on, delineate_with)
					else
  	  			obj << new_element
	  			end
    		else
  				merge_with_attributes(tag, new_element, delineate_on, delineate_with)
    		end
      end
  		
      return sub, new_element
    end

    def end_el(name)
    	# TODO: filter-out untracked cursors
      if true #(name.match(el) if el.is_a? Regexp) || name == el
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
		
		def submodel(tag=current_tag); self.current_tag = tag; get_submodel(tag) || default_submodel end
	  def individual_attributes; submodel['individual_attributes'] end    
	  def hide_attributes; submodel['hide_attributes'] end
    def as_attribute; submodel['as_attribute'] end
  	def delineate_on; submodel['delineate_on'] end
  	def delineate_with; submodel['delineate_with'] || Array end
  	def as; submodel['as']; end
    
    
    def merge_like_elements(cur, new_element, on=nil, with=Hash)
    	case
    		#when !cur; {}
    		when !on; Array[cur].flatten.compact << new_element
    		when with.is_a?(Hash); with[(cur || {})].merge!((ivg(on, new_element) || new_element[on]).to_s => new_element)    			
    		when with.is_a?(Array); with[cur].flatten.compact.find{|c| ivg(on, c) == ivg(on, new_element)} << new_element
    		else new_element
    	end
    end
    
    # TODO: Fix the Hash - it's going deeper each round. See #end_el for filtering untracked cursors.
    # TODO: Add delineate_on capability to the Array (is this even practical?).
    def resolve_conflicts(cur, new_element, on=nil, with=Array)
      with = !with.is_a?(String) ? with : eval(with)
    	case
  	  when with.new.is_a?(Array); with[cur].flatten.compact << new_element
  	  when with.new.is_a?(Hash);
  	    current_key = get_attribute(on, cur)
  	    new_key = get_attribute(on, new_element)
  	    with[current_key => cur].merge(new_key => new_element)
    	end
    end
    
    def get_attribute(name, obj=obj)
      return obj.att[name] rescue nil
      return ivg(name, obj) rescue nil
      return obj[name] rescue nil
    end
    
    def merge_with_attributes(name, element, on, with)
    	set_element_accessor(name, resolve_conflicts(ivg(name), element, on, with))
    end
    
    def merge_with_hash(name, element, on, with)
    	obj[name] = resolve_conflicts(obj[name], element, on, with)
    end
    
    def merge_with_array(name, element, on, with)
    	obj.replace resolve_conflicts(obj, element, on, with)
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

module SaxHandler

	attr_accessor :stack, :grammar
	
	def self.build(io, grammar, parser)
	  (eval(parser.to_s)).build(io, grammar)
  end
  
  def self.included(base)
  
  	# Why doesn't work?
  	# Not necessary, but nice for testing.
			base.send :attr_accessor, :handler

    def base.build(io, grammar)
  		handler = new(grammar)
  		handler.run_parser(io)
  		handler.stack[0].obj   #.cursor
  	end
  	
  	def base.handler
  		@handler
  	end
  end
  
  def initialize(grammar)
  	@stack = []
  	@grammar = YAML.load_file(grammar)
  	# Not necessary - for testing only
  		self.class.instance_variable_set :@handler, self
  	init_element_buffer
    #initial_object.parent = set_cursor initial_object
    #set_cursor grammar, grammar['class']
    set_cursor @grammar, Hash.new
  end
  
	def cursor
		stack.last
	end
	
	def set_cursor(*args) # cursor-object OR model, obj
		args = *args
		# 		puts "SET_CURSOR: #{args.class}"
		# 		y args
		
		args = [{},{}] if args.nil? or args.empty? or args[0].nil? or args[1].nil?

		stack.push(args.is_a?(Cursor) ? args : Cursor.new(args[0], args[1]))# if !args.empty?
		cursor.parent = stack[-2]
		cursor.top = stack[0]
		cursor.stack = stack
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
			cursor.attribute('content', value)
		else
			@element_buffer[:attr].merge!({'content'=>value})
			send_element_buffer
		end
	end
	
	# Close out an existing element.
	def _end_element(value)
		send_element_buffer
		cursor.end_el(value) and dump_cursor   #set_cursor cursor.parent
	end
  
end # SaxHandler



#####  SAX PARSER BACKENDS  #####

class OxFmpSax < ::Ox::Sax

  include SaxHandler

  def run_parser(io)
		#Ox.sax_parse(self, io)
		File.open(io){|f| Ox.sax_parse self, f}
	end
	
  def start_element(name); _start_element(name.to_s.gsub(/\-/, '_'));        	end
  def end_element(name);   _end_element(name.to_s.gsub(/\-/, '_'));          end
  def attr(name, value);   _attribute(name.to_s.gsub(/\-/, '_'), value);     end
  def text(value);         _text(value);                              				end
  
end # OxFmpSax




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
		cursor.parent.obj.merge!(cursor.obj['name'] => (cursor.obj['data']['content'] rescue ''))
	end
end

class RelatedSet < Array
end




#####  DATA  #####

FM = 'local_testing/resultset.xml'
FMP = 'local_testing/resultset_with_portals.xml'
XML = 'local_testing/data_fmpxmlresult.xml'
XMP = 'local_testing/data_with_portals_fmpxmlresult.xml'
LAY = 'local_testing/layout.xml'
XMD = 'local_testing/db_fmpxmlresult.xml'
FMB = 'local_testing/resultset_with_bad_data.xml'
SP = 'local_testing/SplashLayout.xml'

S = StringIO.new(%{
<top name="top01">
	<middle name="middle01" />
  <middle name="middle02">
    <bottom name="bottom01">bottom-text</bottom>
  </middle>
  <middle name="middle03">middle03-text</middle>
</top>
})

