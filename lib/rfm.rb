module Rfm
	PATH = File.expand_path(File.dirname(__FILE__))
	$LOAD_PATH.unshift(PATH) unless $LOAD_PATH.include?(PATH)
end

require 'rfm/utilities/core_ext'
require 'rfm/utilities/case_insensitive_hash'
require 'rfm/utilities/config'
require 'rfm/utilities/factory'
require 'rfm/version.rb'

module Rfm
  
  class CommunicationError  < StandardError; end
  class ParameterError      < StandardError; end
  class AuthenticationError < StandardError; end

  autoload :Error,        'rfm/error'
  autoload :Server,       'rfm/server'
  autoload :Database,     'rfm/database'
  autoload :Layout,       'rfm/layout'
  autoload :Resultset,    'rfm/resultset'
  autoload :Record,       'rfm/record'
  autoload :Base,         'rfm/utilities/base'
  autoload :XmlParser,    'rfm/utilities/xml_parser'
  autoload :ComplexQuery, 'rfm/utilities/complex_query'

	module Metadata
		autoload :Script,         'rfm/metadata/script'
		autoload :Field,          'rfm/metadata/field'
		autoload :FieldControl,   'rfm/metadata/field_control'
		autoload :ValueListItem,  'rfm/metadata/value_list_item'
	end
	
	if $0.to_s.match(/irb|rails|bundle/) # was ENV['_']
  	puts "Using ginjo-rfm version #{::Rfm::VERSION} with #{XmlParser.backend}"
  end
	
	class << self
		def_delegators 'Rfm::Factory', :servers, :server, :db, :database, :layout, :models, :modelize
		def_delegators 'Rfm::XmlParser', :backend, :backend=
		def_delegators 'Rfm::Config', :config, :config_all, :config_clear
	end
	 
end
