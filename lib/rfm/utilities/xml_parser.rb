module Rfm
	module XmlParser
		require 'rubygems'
		
		begin
# 		require 'nokogiri'
# 		puts "Using Nokogiri"
# 		@parser = proc{|*args| Nokogiri.XML(*args)}
# 	rescue LoadError
# 		require 'ox'
# 		@parser = proc{|*args| }
# 	rescue LoadError
# 		require 'libxml'
# 		@parser = proc{|*args| LibXML::XML::Parser.string(*args).parse}
# 	rescue LoadError
# 		require 'hpricot'
# 		Hpricot::Doc.class_eval{alias_method :xpath, :search}
# 		Hpricot::Elements.class_eval{alias_method :xpath, :search}
# 		@parser = proc{|*args| Hpricot.XML(*args)}
# 	rescue LoadError
# 		require 'rexml/document'
# 		puts "Using REXML"
# 		REXML::Element.class_eval{def xpath(str); self.elements[str]; end}
# 		@parser = proc{|*args| REXML::Document.new(*args)}
# 	rescue LoadError
# 		require 'multi_xml'
# 		@parser = proc{|*args| MultiXml.parser = :ox; MultiXml.parse(*args)}
# 	rescue LoadError
			require 'active_support/xml_mini'
			@parser = proc{|*args| ActiveSupport::XmlMini.backend = 'LibXMLSAX'; ActiveSupport::XmlMini.parse(*args)}
		end
		
		def self.new(*args)
			opt = args.pop if args.last.class == Hash
			args[0].gsub!(/xmlns=\"[^\"]*\"/,'') if (args[0].class == String and opt[:namespace] == false)
			@parser.call(*args)
		end
		
	end
end