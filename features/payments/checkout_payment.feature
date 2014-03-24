Feature: User pays after accepted transaction
  In order to pay easily for what I've bought
  As a user
  I want to pay via the platform

  @javascript
  Scenario: User can not accept transaction before filling in payment details
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |
    And community "test" has payments in use via Checkout
    And "kassi_testperson2" does not have Checkout account
    And there is a listing with title "math book" from "kassi_testperson2" with category "Items" and with transaction type "Selling"
    And the price of that listing is "12"
    And there is a message "I want to buy" from "kassi_testperson1" about that listing
    And I am logged in as "kassi_testperson2"
    When I follow "inbox-link"
    And I should see "1" within ".inbox-link"
    And I follow "I want to buy"
    And I follow "Accept request"
    Then I should see information about missing payment details
    When I follow "#conversation-payment-settings-link"
    Then I should be on the payment settings page

  @javascript
  Scenario: User goes to payment service, but decides to cancel and comes back
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |
    And community "test" has payments in use via Checkout
    And "kassi_testperson2" has Checkout account
    And there is a listing with title "math book" from "kassi_testperson2" with category "Items" and with transaction type "Selling"
    And the price of that listing is "12"
    And there is a message "I want to buy" from "kassi_testperson1" about that listing
    And I am logged in as "kassi_testperson2"
    When I follow "inbox-link"
    And I should see "1" within ".inbox-link"
    And I follow "I want to buy"
    And I follow "Accept request"
    And I fill in "conversation_message_attributes_content" with "Ok, then pay!"
    And I press "Send"
    Then I should see "Accepted"
    When I am logged in as "kassi_testperson1"
    And I follow "inbox-link"
    Then I should see "1" within ".inbox-link"
    When I follow "I want to buy"
    Then I should see "Pay"
    When I follow "Pay"
    Then I should see "New payment"
    And I should see "12.00€"
    When I click "#continue_payment"
    Then I should see "Checkout"
    Then I should see "Testi Oy (123456-7)"
    When I pay with Osuuspankki
    Then I should see "Payment successful"
    When I log out
    And the system processes jobs
    Then "kassi_testperson1@example.com" should receive an email
    When I open the email
    Then I should see "You have paid" in the email body
    And "kassi_testperson2@example.com" should receive an email
    When I open the email
    Then I should see "View conversation" in the email body
    When "8" days have passed
    And the system processes jobs
    Then "kassi_testperson1@example.com" should have 2 emails
    When I open the email with subject "Remember to confirm"
    Then I should see "You have not yet confirmed" in the email body
    When "16" days have passed
    And the system processes jobs
    Then "kassi_testperson1@example.com" should have 3 emails
    When "100" days have passed
    And the system processes jobs
    Then "kassi_testperson1@example.com" should have 3 emails
    And return to current time

  @javascript
  Scenario: requester cancels a transaction with payment that had already been accepted, but not paid and skips feedback
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |
    And "kassi_testperson2" has Checkout account
    And community "test" has payments in use via Checkout
    And there is a listing with title "math book" from "kassi_testperson2" with category "Items" and with transaction type "Selling"
    And the price of that listing is "12"
    And there is a message "I want to buy" from "kassi_testperson1" about that listing
    And the request is accepted
    And I am logged in as "kassi_testperson1"
    When I follow "inbox-link"
    And I follow "Cancel"
    And I fill in "Message" with "Sorry I gotta cancel"
    And I choose "Skip feedback"
    And I press "Continue"
    Then I should see "Canceled"
    And I should see "Sorry I gotta cancel"

  @javascript
  Scenario: requester cancels a transaction with payment that had already been accepted, but not paid and gives feedback
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |
    And "kassi_testperson2" has Checkout account
    And community "test" has payments in use via Checkout
    And there is a listing with title "math book" from "kassi_testperson2" with category "Items" and with transaction type "Selling"
    And the price of that listing is "12"
    And there is a message "I want to buy" from "kassi_testperson1" about that listing
    And the request is accepted
    And I am logged in as "kassi_testperson1"
    When I follow "inbox-link"
    And I follow "Cancel"
    And I fill in "Message" with "Sorry I gotta cancel"
    And I choose "Give feedback"
    And I press "Continue"
    Then I should see "Give feedback to"
    And I click "#positive-grade-link"
    And I fill in "How did things go?" with "Good reply, it was me who changed my mind."
    And I press "send_testimonial_button"
    Then I should see "Canceled"
    And I should see "Sorry I gotta cancel"

  @javascript
  Scenario: requester pays with delayed billing
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |
    And community "test" has payments in use
    And "kassi_testperson2" has Checkout account
    And there is a listing with title "math book" from "kassi_testperson2" with category "Items" and with transaction type "Selling"
    And the price of that listing is "12"
    And there is a message "I want to buy" from "kassi_testperson1" about that listing
    And I am logged in as "kassi_testperson2"
    When I follow "inbox-link"
    And I should see "1" within ".inbox-link"
    And I follow "I want to buy"
    And I follow "Accept request"
    And I fill in "conversation_message_attributes_content" with "Ok, then pay!"
    And I press "Send"
    Then I should see "Accepted"
    When I am logged in as "kassi_testperson1"
    When I follow "inbox-link"
    Then I should see "Pay"
    When I follow "Pay"
    Then I should see "New payment"
    And I should see "12.00€"
    When I click "#continue_payment"
    Then I should see "Checkout"
    Then I should see "Testi Oy (123456-7)"
    When I pay by bill
    Then I should see "When you have paid, we'll notify the seller and you will get a receipt in email"
    And I should see "Pay"

  @javascript
  Scenario: offerer cancels the request
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |
    And community "test" has payments in use
    And "kassi_testperson2" has Checkout account
    And there is a listing with title "math book" from "kassi_testperson2" with category "Items" and with transaction type "Selling"
    And the price of that listing is "12"
    And there is a message "I want to buy" from "kassi_testperson1" about that listing
    And I am logged in as "kassi_testperson2"
    When I follow "inbox-link"
    And I should see "1" within ".inbox-link"
    And I follow "I want to buy"
    And I follow "Not this time"
    And I fill in "conversation_message_attributes_content" with "Sorry I'cant sell it!"
    And I press "Send"
    Then I should see "Request rejected"

    When I am logged in as "kassi_testperson1"
    When I follow "inbox-link"
    Then I should see "Rejected"
    Then I should see "Sorry I'cant sell it!"