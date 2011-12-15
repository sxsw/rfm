module Rfm
	module XmlParser # @private :nodoc: all
		require 'thread'
		require 'active_support' unless defined? ActiveSupport
		extend Config
		config :parent=>'Rfm::Config'
		
		extend self
		
		# Backend configurations
		BACKENDS = ActiveSupport::OrderedHash.new
		
		BACKENDS[:jdom]					= {:require=>'jdom',			:class =>	'JDOM'}
		BACKENDS[:libxml]				= {:require=>'libxml',		:class =>	'LibXML'}
		BACKENDS[:libxmlsax]		= {:require=>'libxml',		:class =>	'LibXMLSAX'}
		BACKENDS[:nokogirisax]	= {:require=>'nokogiri',	:class =>	proc{ActiveSupport::VERSION; 'NokogiriSAX'}}
		BACKENDS[:nokogiri]			= {:require=>'nokogiri',	:class =>	'Nokogiri'}
		BACKENDS[:hpricot]			= {:require=>'hpricot',	  :class =>	proc{
																# Hpricot module is part of Rfm, not XmlMini,
																# and needs to be handed manually to XmlMini.
																require File.join(File.dirname(__FILE__), '../xml_mini/hpricot.rb')
																ActiveSupport::XmlMini_Hpricot}}
		BACKENDS[:rexml]				= {:require=>'rexml/document',	:class=>'REXML'}
		
		
		# Main parsing method.
		def new(string_or_file, opts={})
			string_or_file.gsub!(/xmlns=\"[^\"]*\"/,'') if (string_or_file.class == String and opts[:namespace] == false)
			unless opts[:parser] and get_backend_from_hash(opts[:parser]).to_s != self.backend.to_s
				warn "XmlParser default: #{ActiveSupport::XmlMini.backend.to_s}" if get_config[:log_parser] == true
				ActiveSupport::XmlMini.parse(string_or_file)
			else
				warn "XmlParser backend: #{get_backend_from_hash(opts[:parser]).to_s}" if get_config[:log_parser] == true
				ActiveSupport::XmlMini.with_backend(get_backend_from_hash(opts[:parser])) {ActiveSupport::XmlMini.parse(string_or_file)}
			end
		end
				
		# Shortcut to XmlMini config getter.
		# If a parameter is passed, it will be used to get the local backend description
		# from the BACKENDS hash, instead of the XmlMini backend.
		def backend(name=nil)
			return ActiveSupport::XmlMini.backend unless name
			get_backend_from_hash(name)
		end
		
		# Shortcut to XmlMini config setter.
		def backend=(name)
			if name.is_a? Symbol
				set_backend_via_hash(name)
			else
				ActiveSupport::XmlMini.backend = name
			end
		end
		
	private
		
		# Given name, return backend config from BACKENDS, including any preloading.
		# Will raise LoadError if can't load backend.
		def get_backend_from_hash(name)
				backend_hash = BACKENDS[name.to_sym]
				require backend_hash[:require]
				backend_hash[:class].is_a?(Proc) ? backend_hash[:class].call : backend_hash[:class]
		end
		
		# Set XmlMini backend, given symbol matching one of the BACKENDS.
		def set_backend_via_hash(name)
			ActiveSupport::XmlMini.backend = get_backend_from_hash(name)
		end
		
		# Select the best backend from BACKENDS, returns backend config.
		def decide_backend
			string_or_class = catch(:done) do
				BACKENDS.keys.each do |name|
					begin
						result = get_backend_from_hash name
						throw(:done, result)
					rescue LoadError, StandardError
					end
				end
			end
		end
				
		# Set XmlMini backend when this file loads.
		begin
			self.backend = get_backend_from_hash(get_config[:parser])
		rescue
			self.backend = decide_backend
		end
		
	end # XmlParser
end # Rfm
