class CustomField < ActiveRecord::Base
  include SortableByPriority # use `sort_priority()` for sorting
  
  attr_accessible(
    :type,
    :name_attributes,
    :category_attributes,
    :option_attributes,
    :sort_priority,
    :required,
    :min,
    :max
  )
  
  has_many :names, :class_name => "CustomFieldName", :dependent => :destroy

  has_many :category_custom_fields, :dependent => :destroy
  has_many :categories, :through => :category_custom_fields

  has_many :answers, :class_name => "CustomFieldValue", :dependent => :destroy
  
  has_many :options, :class_name => "CustomFieldOption"
  
  belongs_to :community
  
  VALID_TYPES = ["Dropdown", "TextField", "NumericField"]

  validates_length_of :names, :minimum => 1
  validates_length_of :category_custom_fields, :minimum => 1
  validates_presence_of :community
  
  def name_attributes=(attributes)
    build_attrs = attributes.map { |locale, value| {locale: locale, value: value } }
    build_attrs.each do |name| 
      if existing_name = names.find_by_locale(name[:locale])
        existing_name.update_attribute(:value, name[:value])
      else
        names.build(name)
      end
    end
  end
  
  def category_attributes=(attributes)
    category_custom_fields.clear
    attributes.each { |category| category_custom_fields.build(category) }
  end

  def name(locale="en")
    TranslationCache.new(self, :names).translate(locale, :value)
  end

  def answer_for(listing)
    # This seems somewhat ugly. A model shouldn't know this much about other modules.
    # In addition, this triggers database query from view layer, which is ugly.
    # I hope this can be simplified after the transaction_type/share_type refactoring
    CustomFieldValue.find_by_listing_id_and_custom_field_id(listing.id, self.id)
  end

  def with(expected_type, &block)
    with_type do |own_type|
      if own_type == expected_type
        block.call
      end
    end
  end

  def with_type(&block)
    throw "Implement this in the subclass"
  end

end
