module Rfm
  PATH = File.expand_path(File.dirname(__FILE__))
  $LOAD_PATH.unshift(PATH) unless $LOAD_PATH.include?(PATH)
end

#require 'thread' # some versions of ActiveSupport will raise error about Mutex unless 'thread' is loaded.

require 'logger'
require 'rfm/utilities/core_ext'
require 'rfm/utilities/case_insensitive_hash'

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
  autoload :Base,         'rfm/base'
  autoload :SaxParser,    'rfm/utilities/sax_parser'
  autoload :Config,       'rfm/utilities/config'
  autoload :Factory,      'rfm/utilities/factory'
  autoload :CompoundQuery,'rfm/utilities/compound_query'
  autoload :VERSION,      'rfm/version'
  autoload :Connection,   'rfm/utilities/connection.rb'
  autoload :Scope,        'rfm/utilities/scope.rb'

  module Metadata
    autoload :Script,         'rfm/metadata/script'
    autoload :Field,          'rfm/metadata/field'
    autoload :FieldControl,   'rfm/metadata/field_control'
    autoload :ValueListItem,  'rfm/metadata/value_list_item'
    autoload :Datum,          'rfm/metadata/datum'
    autoload :ResultsetMeta,  'rfm/metadata/resultset_meta'
    autoload :LayoutMeta,     'rfm/metadata/layout_meta'
  end

  def info
    rslt = <<-EEOOFF
      Gem name: ginjo-rfm
      Version: #{VERSION}
      ActiveModel loadable? #{begin; Gem::Specification::find_all_by_name('activemodel')[0].version.to_s; rescue Exception; false; end}
      ActiveModel loaded? #{defined?(ActiveModel) ? 'true' : 'false'}
      XML default parser: #{SaxParser::Handler.get_backend}
      Ruby: #{RUBY_VERSION}
    EEOOFF
    rslt.gsub!(/^[ \t]*/, '')
    rslt
  rescue
    "Could not retrieve info: #{$!}"
  end

  def info_short
    "Using ginjo-rfm version #{::Rfm::VERSION} with #{SaxParser::Handler.get_backend}"
  end

  def_delegators 'Rfm::Factory', :servers, :server, :db, :database, :layout
  def_delegators 'Rfm::Config', :config, :get_config, :config_clear
  def_delegators 'Rfm::Resultset', :load_data

  def models(*args)
    Rfm::Factory.models(*args)
  end

  def modelize(*args)
    Rfm::Factory.modelize(*args)
  end

  def logger
    @@logger ||= get_config[:logger] || Logger.new(STDOUT).tap {|l| l.formatter = proc {|severity, datetime, progname, msg| "#{datetime}: Rfm-#{severity} #{msg}\n"}}
  end

  alias_method :log, :logger

  def logger=(obj)
    @@logger = obj
  end

  # DEFAULT_CLASS = CaseInsensitiveHash
  # TEMPLATE_PREFIX = File.join(File.dirname(__FILE__), 'rfm/utilities/sax/')
  # TEMPLATES = {
  #   :fmpxmllayout => 'fmpxmllayout.yml',
  #   :fmresultset => 'fmresultset.yml',
  #   :fmpxmlresult => 'fmpxmlresult.yml',
  #   :none => nil
  # }

  PARSER_DEFAULTS = {
    :default_class => CaseInsensitiveHash,
    :template_prefix => File.join(File.dirname(__FILE__), 'rfm/utilities/sax/'),
    :templates => {
      :fmpxmllayout => 'fmpxmllayout.yml',
      :fmresultset => 'fmresultset.yml',
      :fmpxmlresult => 'fmpxmlresult.yml',
      :none => nil
    }
  }

  extend self

end # Rfm
