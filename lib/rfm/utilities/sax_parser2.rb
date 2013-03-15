# From https://github.com/ohler55/ox
# Do: irb -rubygems -r  lib/rfm/utilities/sax_parser.rb
# Do: r = OxFmpSax.build(FM, 'local_testing/sax_parser.yml')

#gem 'ox', '1.8.5'
require 'stringio'
require 'ox'
require 'delegate'
require 'yaml'
require 'rfm'


class Cursor

    attr_accessor :model, :obj
    
    def self.constantize(klass)
	  	Object.const_get(klass.to_s) rescue nil
	  end
    
    def initialize(model, obj)
    	@model = model
    	@obj   = obj.is_a?(String) ? constantize(obj).new : obj
    	self
    end
    
	  def constantize(klass)
	  	self.class.constantize(klass)
	  end
    
		def get_submodel(name)
			#puts "Cursor#get_submodel: #{name}"
			model['elements'][name] rescue nil #|| default_submodel rescue default_submodel
		end
		
		def default_submodel
			if model['depth'].to_i > 0
				{'elements' => model['elements'], 'depth'=>(model['depth'].to_i - 1)}
			else
				{}
			end
		end
    
    def attribute(name,value); (obj[name]=value) rescue nil end
        
    def start_el(tag, attributes)
    	#puts "Cursor#start_el: #{tag}"
    	
    	return if (model['ignore_unknown']  && !model['elements'][tag])
    	
    	# Acquire submodel grammar
      submodel = get_submodel(tag) || default_submodel
      
      # Create new element
      new_element = (constantize(submodel['class'].to_s) || Hash).new 
      
      # Assign attributes to new element
      if !attributes.empty?
	      new_element.is_a?(Hash) ? new_element.merge!(attributes) : new_element.instance_variable_set(:@attributes, attributes)
      end
      
      # Store new object in current object
      #puts "Submodel: #{submodel['class']}"
  		if obj.is_a?(Hash) && !submodel['hidden']
  			if obj.has_key? tag
  				obj[tag] = [obj[tag]].flatten << new_element
		    else			
  				obj[tag] = new_element
  			end
  		elsif obj.is_a? Array
  			if submodel['hidden'] == false
	  			set_element_accessor(tag, new_element)
  			else
	  			obj << new_element
  			end
  		else
				set_element_accessor(tag, new_element)
  		end
  		
      #yield(self) if block_given?
      return submodel, new_element
    end
    
    def set_element_accessor(tag, new_element)
			#obj.instance_variable_set "@#{tag}", new_element
			if obj.respond_to? tag
				obj.send "#{tag}=",   ([obj.send "#{tag}"].flatten << new_element)
			else
				create_accessor tag
				obj.send "#{tag}=", new_element
			end
		end
		
		def create_accessor(tag)
			obj.class.class_eval do
				attr_accessor "#{tag}"
			end
		end
		
    def end_el(name)
    	#puts "Cursor#end_el: #{name}" 
      if true #(name.match(el) if el.is_a? Regexp) || name == el
        #yield(self) if block_given?
        return true
      end
    end

end # Cursor


module SaxHandler

	attr_accessor :stack, :grammar
  
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
	#   start_el /.*/i, :Hash
end

class Metadata < Array
end

class Resultset < Array
end

class Record < Hash
	# 	start_el 'field', :Hash do |slf|
	# 		slf.merge!(slf._new_element['name'] => slf._new_element['content'])
	# 	end
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

