class CustomFieldOptionSelection < ActiveRecord::Base
  # WARNING! This expects that there's only one selection (Dropdown). 
  # If there are multiple selections, the custom_field_value should not be deleted 
  # if one of the selected options are deleted
  belongs_to :custom_field_value, dependent: :destroy
  belongs_to :custom_field_option
end