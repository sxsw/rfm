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
			require 'rexml/document'
			puts "Using REXML"
			REXML::Element.class_eval{def xpath(str); self.elements[str]; end}
			@parser = proc{|*args| REXML::Document.new(*args)}
		end
		
		def self.new(*args)
			opt = args.pop if args.last.class == Hash
			args[0].gsub!(/xmlns=\"[^\"]*\"/,'') if (args[0].class == String and opt[:namespace] == false)
			@parser.call(*args)
		end
		
		
	# # Nokogiri xpath to FM record data. Remember to remove namespace or xpath won't work.
	# 	N = Nokogiri.XML X
	# 	puts N.xpath("//resultset/record[1]/field[@name='MemoText']/data[1]/text()").to_s
	# 
	# # Hpricot xpath to FM record data
	# 	H = Hpricot.XML(X)
	# 	puts H.search("//resultset/record[1]/field[@name='MemoText']/data[1]/text()").to_s
	# 	
	# # Rexml xpath to FM record data
	# 	R = REXML::Document.new(X)
	# 	puts R.root.elements["//resultset/record[1]/field[@name='MemoText']/data[1]/text()"].to_s
	# 	
	# # Libxml xpath to FM record data
	# 	L = LibXML::XML::Parser.string(X).parse
	# 	puts L.find("//resultset/record[1]/field[@name='MemoText']/data[1]/text()").to_a.to_s
	# 	
	# # Multixml xpath to FM record data
	# 	MultiXml.parser = :rexml
	# 	M = MultiXml.parse(X)
	# 	puts M.find("//resultset/record[1]/field[@name='MemoText']/data[1]/text()").to_s
	# 
	# # Add 'xpath' method to Hpricot & REXML, so they work like Nokogiri
	# 	Hpricot::Doc.class_eval{alias_method :xpath, :search}
	# 	Hpricot::Elements.class_eval{alias_method :xpath, :search}
	# 	REXML::Element.class_eval{def xpath(str); self.elements[str]; end}
	# 	
	# 	puts N.xpath("//resultset/record[2]/field[@name='MemoText']/data[1]/text()").to_s
	# 	puts H.xpath("//resultset/record[2]/field[@name='MemoText']/data[1]/text()").to_s
	# 	puts R.xpath("//resultset/record[2]/field[@name='MemoText']/data[1]/text()").to_s
	
	
	
	end
end