module Rfm
	module XmlParser
		require 'rubygems'
		require 'active_support'
		require 'active_support/xml_mini'
		
		extend self
		
		# Backend configurations
		BACKENDS = ActiveSupport::OrderedHash.new
		
		BACKENDS[:jdom]					= {:require=>'jdom',			:class=>'JDOM'}
		BACKENDS[:libxml]				= {:require=>'libxml',		:class=>'LibXML'}
		BACKENDS[:libxmlsax]		= {:require=>'libxml',		:class=>'LibXMLSAX'}
		BACKENDS[:nokogirisax]	= {:require=>'nokogiri',	:class=>'NokogiriSAX'}
		BACKENDS[:nokogiri]			= {:require=>'nokogiri',	:class=>'Nokogiri'}
		BACKENDS[:hpricot]			= {:require=>'hpricot',	:class=>proc{
																# Hpricot module is part of Rfm, not XmlMini,
																# and needs to be handed manually to XmlMini.
																require File.join(File.dirname(__FILE__), '../xml_mini/hpricot.rb')
																ActiveSupport::XmlMini_Hpricot}}
		BACKENDS[:rexml]				= {:require=>'rexml/document',	:class=>'REXML'}
		
		
		# Main parsing method.
		def new(string_or_file, opts={})
			string_or_file.gsub!(/xmlns=\"[^\"]*\"/,'') if (string_or_file.class == String and opts[:namespace] == false)
			unless opts[:backend]
				ActiveSupport::XmlMini.parse(string_or_file)
			else
				ActiveSupport::XmlMini.with_backend(get_backend(opts[:backend])) {ActiveSupport::XmlMini.parse(string_or_file)}
			end
		end
				
		# Shortcut to XmlMini config getter.
		def backend
			ActiveSupport::XmlMini.backend
		end
		
		# Shortcut to XmlMini config setter.
		def backend=(string_or_class)
			ActiveSupport::XmlMini.backend = string_or_class
		end		
		
		# Given name, return backend config from BACKENDS, including any preloading.
		# Will raise LoadError if can't load backend.
		def get_backend(name)
				backend_hash = BACKENDS[name.to_sym]
				require backend_hash[:require]
				backend_hash[:class].is_a?(Proc) ? backend_hash[:class].call : backend_hash[:class]
		end
		
		# Set XmlMini backend, given symbol matching one of the BACKENDS.
		def set_backend(name)
			self.backend = get_backend(name)
		end
		
		# Select the best backend, returns backend config.
		def decide_backend
			string_or_class = catch(:done) do
				BACKENDS.keys.each do |name|
					begin
						result = get_backend name
						throw(:done, result)
					rescue LoadError
					end
				end
			end
		end
		
		# Give hash & arry a method to always return an array,
		# since XmlMini doesn't know which will be returnd for any particular element.
		# See Rfm Layout & Record where this is used.
		class ::Hash
			def ary
				[self]
			end
		end
		
		class ::Array
			def ary
				self
			end
		end
		
		# Set XmlMini backend when this file loads.
		begin
			self.backend = get_backend FM_CONFIG[:backend]
		rescue
			self.backend = decide_backend
		end
		
	end # XmlParser
end # Rfm
