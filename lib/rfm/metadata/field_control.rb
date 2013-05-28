module Rfm
	module Metadata
	
	  # The FieldControl object represents a field on a FileMaker layout. You can find out what field
	  # style the field uses, and the value list attached to it.
	  #
	  # =Attributes
	  #
	  # * *name* is the name of the field
	  #
	  # * *style* is any one of:
	  # * * :edit_box - a normal editable field
	  # * * :scrollable - an editable field with scroll bar
	  # * * :popup_menu - a pop-up menu
	  # * * :checkbox_set - a set of checkboxes
	  # * * :radio_button_set - a set of radio buttons
	  # * * :popup_list - a pop-up list
	  # * * :calendar - a pop-up calendar
	  #
	  # * *value_list_name* is the name of the attached value list, if any
	  # 
	  # * *value_list* is an array of strings representing the value list items, or nil
	  #   if this field has no attached value list
	  class FieldControl
	    attr_reader :name, :style, :value_list_name
	    meta_attr_accessor :layout_meta
	  
	  	def initialize(attributes, meta)
	  		self.layout_meta = meta
	  		_attach_as_instance_variables attributes
	  		self
	  	end
	  	
	  	# Handle manual attachment of STYLE element.
	  	def handle_style_element(attributes)
	  		_attach_as_instance_variables attributes, :key_translator=>method(:translate_value_list_key), :value_translator=>method(:translate_style_value)
	  	end
	  	
	  	def translate_style_value(raw)
	  		#puts ["TRANSLATE_STYLE", raw].join(', ')
	  		{
	  			'EDITTEXT'	=>	:edit_box,
					'POPUPMENU'	=>	:popup_menu,
					'CHECKBOX'	=>	:checkbox_set,
					'RADIOBUTTONS'	=>	:radio_button_set,
					'POPUPLIST'	=>	:popup_list,
					'CALENDAR'	=>	:calendar,
					'SCROLLTEXT'	=>	:scrollable,
	  		}[raw] || raw
	  	end
	  	
	  	def translate_value_list_key(raw)
				{'valuelist'=>'value_list_name'}[raw] || raw	  	
	  	end
	  	
	  	def value_list
	  		layout_meta.field_controls[value_list_name]
	  	end
	  
			#   def initialize(name, style, value_list_name, value_list)
			#     @name = name
			#     case style
			#     when "EDITTEXT"
			#       @style = :edit_box
			#     when "POPUPMENU"
			#       @style = :popup_menu
			#     when "CHECKBOX"
			#       @style = :checkbox_set
			#     when "RADIOBUTTONS"
			#       @style = :radio_button_set
			#     when "POPUPLIST"
			#       @style = :popup_list
			#     when "CALENDAR"
			#       @style = :calendar
			#     when "SCROLLTEXT"
			#       @style = :scrollable
			#     else
			#       nil
			#     end
			#     @value_list_name = value_list_name
			#     rfm_metaclass.instance_variable_set :@value_list, value_list
			#   end

	  end
	end
end