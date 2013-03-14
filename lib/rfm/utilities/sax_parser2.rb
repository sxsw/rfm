# From https://github.com/ohler55/ox
# Do: irb -rubygems -r  lib/rfm/utilities/sax_parser.rb
# Do: y rslt = OxFmpSax.build(FM, FmResultset.new)

#gem 'ox', '1.8.5'
require 'stringio'
require 'ox'
require 'delegate'
require 'yaml'
require 'rfm'


class Cursor

    attr_accessor :model, :obj
    
    def self.constantize(klass)
	  	Object.const_get(klass.to_s) rescue Hash
	  end
    
    def initialize(model, obj)
    	self.model = model
    	self.obj   = obj.is_a?(String) ? constantize(obj).new : obj
    	self
    end
    
	  def constantize(klass)
	  	self.class.constantize(klass)
	  end
    
		def get_submodel(name)
			#puts "Cursor#get_submodel: #{name}"
			model['elements'][name] || default_submodel rescue default_submodel
		end
		
		def default_submodel
			{'elements' => model['elements']}
		end
    
    def attribute(name,value); (obj[name]=value) rescue nil end
        
    def start_el(name, attributes)
    	#puts "Cursor#start_el: #{name}"
      submodel = get_submodel(name)
      new_element = constantize(submodel['class'].to_s).new
      new_element.merge!(attributes) rescue nil
      
  		if obj.is_a? Hash
  			if obj.has_key? name
  				obj[name] = [obj[name]].flatten << new_element
		    else			
  				obj[name] = new_element
  			end
  		elsif obj.is_a? Array
  			obj << new_element
  		else
  			obj.instance_variable_set "@#{name}", new_element
  		end
  		
      #yield(self) if block_given?
      return submodel, new_element
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
  	@grammar = grammar
  	# Not necessary - for testing only
  		self.class.instance_variable_set :@handler, self
  	init_element_buffer
    #initial_object.parent = set_cursor initial_object
    #set_cursor grammar, grammar['class']
    set_cursor grammar, Hash.new
  end
  
	def cursor
		stack.last
	end
	
	def set_cursor(*args) # cursor-object OR model, obj
		args = *args
		#puts "SET_CURSOR: #{args.class}"
		#y args
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

