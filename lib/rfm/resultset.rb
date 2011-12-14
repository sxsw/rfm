# This module includes classes that represent FileMaker data. When you communicate with FileMaker
# using, ie, the Layout object, you typically get back ResultSet objects. These contain Records,
# which in turn contain Fields, Portals, and arrays of data.
#
# Author::    Geoff Coffey  (mailto:gwcoffey@gmail.com)
# Copyright:: Copyright (c) 2007 Six Fried Rice, LLC and Mufaddal Khumri
# License::   See MIT-LICENSE for details

require 'bigdecimal'
require 'rfm/record'

module Rfm

  # The ResultSet object represents a set of records in FileMaker. It is, in every way, a real Ruby
  # Array, so everything you expect to be able to do with an Array can be done with a ResultSet as well.
  # In this case, the elements in the array are Record objects.
  #
  # Here's a typical example, displaying the results of a Find:
  #
  #   myServer = Rfm::Server.new(...)
  #   results = myServer["Customers"]["Details"].find("First Name" => "Bill")
  #   results.each {|record|
  #     puts record["First Name"]
  #     puts record["Last Name"]
  #     puts record["Email Address"]
  #   }
  #
  # =Attributes
  #
  # The ResultSet object has these attributes:
  #
  # * *field_meta* is a hash with field names for keys and Field objects for values; it provides 
  #   info about the fields in the ResultSet
  #
  # * *portal_meta* is a hash with table occurrence names for keys and arrays of Field objects for values;
  #   it provides metadata about the portals in the ResultSet and the Fields on those portals

  class Resultset < Array
    
    #meta_attr_reader :layout, :server
    attr_reader :layout, :server
    attr_reader :field_meta, :portal_meta
    attr_reader :date_format, :time_format, :timestamp_format
    attr_reader :total_count, :foundset_count
    def_delegator :layout, :db
    
    # Initializes a new ResultSet object. You will probably never do this your self (instead, use the Layout
    # object to get various ResultSet obejects).
    #
    # If you feel so inclined, though, pass a Server object, and some +fmpxmlresult+ compliant XML in a String.
    #
    # =Attributes
    #
    # The ResultSet object includes several useful attributes:
    #
    # * *fields* is a hash (with field names for keys and Field objects for values). It includes an entry for
    #   every field in the ResultSet. Note: You don't use Field objects to access _data_. If you're after 
    #   data, get a Record object (ResultSet is an array of records). Field objects tell you about the fields
    #   (their type, repetitions, and so forth) in case you find that information useful programmatically.
    #
    #   Note: keys in the +fields+ hash are downcased for convenience (and [] automatically downcases on 
    #   lookup, so it should be seamless). But if you +each+ a field hash and need to know a field's real
    #   name, with correct case, do +myField.name+ instead of relying on the key in the hash.
    #
    # * *portals* is a hash (with table occurrence names for keys and Field objects for values). If your
    #   layout contains portals, you can find out what fields they contain here. Again, if it's the data you're
    #   after, you want to look at the Record object.
    
    def initialize(server_obj, xml_response, layout_obj, portals=nil)
      @layout           = layout_obj
      @server           = server_obj
      @field_meta     ||= Rfm::CaseInsensitiveHash.new
      @portal_meta    ||= Rfm::CaseInsensitiveHash.new
      @include_portals  = portals 
      
      doc = XmlParser.new(xml_response, :namespace=>false, :parser=>server.state[:parser])
      
      error = doc['fmresultset']['error']['code'].to_i
      check_for_errors(error, server.state[:raise_on_401])

      datasource        = doc['fmresultset']['datasource']
      meta              = doc['fmresultset']['metadata']
      resultset         = doc['fmresultset']['resultset']

      @date_format      = convert_date_time_format(datasource['date-format'].to_s)
      @time_format      = convert_date_time_format(datasource['time-format'].to_s)
      @timestamp_format = convert_date_time_format(datasource['timestamp-format'].to_s)

      @foundset_count   = resultset['count'].to_s.to_i
      @total_count      = datasource['total-count'].to_s.to_i
      
      return if resultset['record'].nil?

      parse_fields(meta)
      parse_portals(meta) if @include_portals and !meta['relatedset-definition'].nil?
      Rfm::Record.build_records(resultset['record'].rfm_force_array, self, @field_meta, layout)
      
    end
        
    def field_names
    	layout.instance_variable_get(:@field_names) ||
    	layout.instance_variable_set(:@field_names, field_meta.collect{|k,v| v.name})
  	end
    
    
    private
    
      def check_for_errors(code, raise_401)
        raise Rfm::Error.getError(code) if code != 0 && (code != 401 || raise_401)
      end
    
      def parse_fields(meta)
        meta['field-definition'].rfm_force_array.each do |field|
          @field_meta[field['name']] = Rfm::Metadata::Field.new(field)
        end
      end

      def parse_portals(meta)
      	return if meta['relatedset-definition'].blank?
        meta['relatedset-definition'].rfm_force_array.each do |relatedset|
        	next if relatedset.blank?
          table, fields = relatedset['table'], {}

          relatedset['field-definition'].rfm_force_array.each do |field|
            name = field['name'].to_s.gsub(Regexp.new(table + '::'), '')
            fields[name] = Rfm::Metadata::Field.new(field)
          end

          @portal_meta[table] = fields
        end
      end
    
      def convert_date_time_format(fm_format)
        fm_format.gsub!('MM', '%m')
        fm_format.gsub!('dd', '%d')
        fm_format.gsub!('yyyy', '%Y')
        fm_format.gsub!('HH', '%H')
        fm_format.gsub!('mm', '%M')
        fm_format.gsub!('ss', '%S')
        fm_format
      end
    
  end
end