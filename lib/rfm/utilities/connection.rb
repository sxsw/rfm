require 'net/https'
require 'cgi'
module Rfm
	DEFAULT_CLASS = CaseInsensitiveHash
	
  class Connection
  	include Config  	
  
		def initialize(action, prms, request_options={}, *args)
    	#config :parent => 'Rfm::Config'
    	options = get_config(*args)
    	config sanitize_config(options, {}, true)
      
      @action = action
      @prms = prms
      @request_options = request_options
      
      @defaults = {
        :host => 'localhost',
        :port => 80,
        :ssl => true,
        :root_cert => true,
        :root_cert_name => '',
        :root_cert_path => '/',
        :account_name => '',
        :password => '',
        :log_actions => false,
        :log_responses => false,
        :log_parser => false,
        :warn_on_redirect => true,
        :raise_on_401 => false,
        :timeout => 60,
        :ignore_bad_data => false,
        :grammar => 'fmresultset'
      }   #.merge(options)
    end

    def state(*args)
    	@defaults.merge(get_config(*args))
    end
    
	  def host_name; state[:host]; end
	  def scheme; state[:ssl] ? "https" : "http"; end
	  def port; state[:ssl] && state[:port].nil? ? 443 : state[:port]; end

    def connect(action=@action, args=@prms, options = @request_options, account_name=state[:account_name], password=state[:password])
    	grammar_option = options.delete(:grammar)
      post = args.merge(expand_options(options)).merge({action => ''})
      grammar = select_grammar(post, :grammar=>grammar_option)
      http_fetch(host_name, port, "/fmi/xml/#{grammar}.xml", account_name, password, post)
    end

    def select_grammar(post, options={})
			grammar = state(options)[:grammar] || 'fmresultset'
			if grammar.to_s.downcase == 'auto'
				post.keys.find(){|k| %w(-find -findall -dbnames -layoutnames -scriptnames).include? k.to_s} ? "FMPXMLRESULT" : "fmresultset"   
    	else
    		grammar
    	end
    end
    
    def parse
    	sax_config = File.join(File.dirname(__FILE__), "../sax/fmresultset.yml")
    	Rfm::SaxParser::Handler.build(connect.body, nil, sax_config, self).result
    end

  private
  
    def http_fetch(host_name, port, path, account_name, password, post_data, limit=10)
      raise Rfm::CommunicationError.new("While trying to reach the Web Publishing Engine, RFM was redirected too many times.") if limit == 0
  
      if state[:log_actions] == true
        #qs = post_data.collect{|key,val| "#{CGI::escape(key.to_s)}=#{CGI::escape(val.to_s)}"}.join("&")
        qs_unescaped = post_data.collect{|key,val| "#{key.to_s}=#{val.to_s}"}.join("&")
        #warn "#{@scheme}://#{@host_name}:#{@port}#{path}?#{qs}"
        warn "#{scheme}://#{host_name}:#{port}#{path}?#{qs_unescaped}"
      end
  
      request = Net::HTTP::Post.new(path)
      request.basic_auth(account_name, password)
      request.set_form_data(post_data)
  
      response = Net::HTTP.new(host_name, port)
      #ADDED LONG TIMEOUT TIMOTHY TING 05/12/2011
      response.open_timeout = response.read_timeout = state[:timeout]
      if state[:ssl]
        response.use_ssl = true
        if state[:root_cert]
          response.verify_mode = OpenSSL::SSL::VERIFY_PEER
          response.ca_file = File.join(state[:root_cert_path], state[:root_cert_name])
        else
          response.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end
  
      response = response.start { |http| http.request(request) }
      if state[:log_responses] == true
        response.to_hash.each { |key, value| warn "#{key}: #{value}" }
        warn response.body
      end
  
      case response
      when Net::HTTPSuccess
        response
      when Net::HTTPRedirection
        if state[:warn_on_redirect]
          warn "The web server redirected to " + response['location'] + 
          ". You should revise your connection hostname or fix your server configuration if possible to improve performance."
        end
        newloc = URI.parse(response['location'])
        http_fetch(newloc.host, newloc.port, newloc.request_uri, account_name, password, post_data, limit - 1)
      when Net::HTTPUnauthorized
        msg = "The account name (#{account_name}) or password provided is not correct (or the account doesn't have the fmxml extended privilege)."
        raise Rfm::AuthenticationError.new(msg)
      when Net::HTTPNotFound
        msg = "Could not talk to FileMaker because the Web Publishing Engine is not responding (server returned 404)."
        raise Rfm::CommunicationError.new(msg)
      else
        msg = "Unexpected response from server: #{response.code} (#{response.class.to_s}). Unable to communicate with the Web Publishing Engine."
        raise Rfm::CommunicationError.new(msg)
      end
    end
  
    def expand_options(options)
      result = {}
      options.each do |key,value|
        case key
        when :max_portal_rows
        	result['-relatedsets.max'] = value
        	result['-relatedsets.filter'] = 'layout'
        when :max_records
          result['-max'] = value
        when :skip_records
          result['-skip'] = value
        when :sort_field
          if value.kind_of? Array
            raise Rfm::ParameterError.new(":sort_field can have at most 9 fields, but you passed an array with #{value.size} elements.") if value.size > 9
            value.each_index { |i| result["-sortfield.#{i+1}"] = value[i] }
          else
            result["-sortfield.1"] = value
          end
        when :sort_order
          if value.kind_of? Array
            raise Rfm::ParameterError.new(":sort_order can have at most 9 fields, but you passed an array with #{value.size} elements.") if value.size > 9
            value.each_index { |i| result["-sortorder.#{i+1}"] = value[i] }
          else
            result["-sortorder.1"] = value
          end
        when :post_script
          if value.class == Array
            result['-script'] = value[0]
            result['-script.param'] = value[1]
          else
            result['-script'] = value
          end
        when :pre_find_script
          if value.class == Array
            result['-script.prefind'] = value[0]
            result['-script.prefind.param'] = value[1]
          else
            result['-script.presort'] = value
          end
        when :pre_sort_script
          if value.class == Array
            result['-script.presort'] = value[0]
            result['-script.presort.param'] = value[1]
          else
            result['-script.presort'] = value
          end
        when :response_layout
          result['-lay.response'] = value
        when :logical_operator
          result['-lop'] = value
        when :modification_id
          result['-modid'] = value
        else
          raise Rfm::ParameterError.new("Invalid option: #{key} (are you using a string instead of a symbol?)")
        end
      end
      return result
    end  
  
  end # Connection
  
	#####  USER MODELS  #####
			
	class FmResultset < Hash
	end
	
	class Datasource < Hash
	end
	
	class Meta < Array
	end
	
	class Resultset# < Array
		def attach_parent_objects(cursor)
			elements = cursor._parent._obj
			elements.each{|k, v| cursor.set_attr_accessor(k, v) unless k == 'resultset'}
			# Why is this here? Seems to need it... how does it work?
			cursor._stack.unshift cursor
		end
	end
	
	class Record# < Hash
		def [](*args)
			super
		end
		def []=(*args)
			super
		end
	end
	
	class Metadata::Field# < Hash
		# This easy way requires the 'compact' parsing option to be true.
		def build_record_data(cursor)
			cursor._parent._obj.merge!(att => data )
		end
		# This is the harder way - when not using the 'compact' parsing option.
		# 		def build_record_data(cursor)
		# 			dat = data
		# 			dat = case
		# 				when dat.is_a?(Array); dat.collect{|d| d['text'] if d.is_a? Hash}.compact.join(', ')
		# 				when data.is_a?(Hash); dat['text']
		# 			end
		# 			cursor._parent._obj.merge!(self.att['name'] => dat )
		# 		end
	end
	
	class RelatedSet < Array
	end
  
  
  
  
end # Rfm