class TransactionTypeTranslation < ActiveRecord::Base
  attr_accessible :action_button_label, :locale, :name, :transaction_type_id

  belongs_to :transaction_type, touch: true

  validates_presence_of :transaction_type
  validates_presence_of :locale
end
