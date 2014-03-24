class BraintreeAccount < ActiveRecord::Base
  attr_accessor :account_number # Not persisted, only sent to Braintree

  belongs_to :person
  belongs_to :community

  validates_presence_of :person
  validates_presence_of :first_name
  validates_presence_of :last_name
  validates_presence_of :email
  validates_format_of :email, :with => /^[A-Z0-9._%\-\+\~\/]+@([A-Z0-9-]+\.)+[A-Z]{2,4}$/i
  validates_presence_of :address_street_address
  validates_presence_of :address_postal_code
  validates_presence_of :address_locality
  validates_presence_of :address_region
  validates_presence_of :date_of_birth
  validates_presence_of :routing_number
  validates_presence_of :hidden_account_number # Persisted version of account number
end
