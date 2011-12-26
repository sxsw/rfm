begin
  require 'ox'
rescue LoadError => e
  $stderr.puts "You don't have Ox installed in your application. Please add it to your Gemfile and run bundle install"
  raise e
end
require 'active_support/core_ext/object/blank'
require 'stringio'

# = XmlMini Ox implementation using a SAX-based parser
# This Ox Sax parser was lifted directly from multi_xml gem.
module ActiveSupport
  module XmlMini_OxSAX # @private :nodoc: all

    extend self
    
    def parse_error
      Exception
    end

    def parse(io)
      if !io.respond_to?(:read)
        io = StringIO.new(io || '')
      end
      handler = Handler.new
      ::Ox.sax_parse(handler, io, :convert_special => true)
      handler.doc
    end



    class Handler
      attr_accessor :stack

      def initialize()
        @stack = []
      end
      
      def doc
        @stack[0]
      end

      def attr(name, value)
        unless @stack.empty?
          append(name, value)
        end
      end

      def text(value)
        append('__content__', value)
      end

      def cdata(value)
        append('__content__', value)
      end

      def start_element(name)
        if @stack.empty?
          @stack.push(Hash.new)
        end
        h = Hash.new
        append(name, h)
        @stack.push(h)
      end

      def end_element(name)
        @stack.pop()
      end

      def error(message, line, column)
        raise Exception.new("#{message} at #{line}:#{column}")
      end

      def append(key, value)
        key = key.to_s
        h = @stack.last
        if h.has_key?(key)
          v = h[key]
          if v.is_a?(Array)
            v << value
          else
            h[key] = [v, value]
          end
        else
          h[key] = value
        end
      end

    end # Handler
  end
end
