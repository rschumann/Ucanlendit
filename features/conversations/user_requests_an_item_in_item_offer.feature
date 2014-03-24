Feature: User requests an item in item offer
  In order to borrow an item from another person
  As a person who needs that item
  I want to be able to send a message to the person who offers the item
  
  @javascript
  Scenario: Borrowing an item from the listing page
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |
    And there is a listing with title "Hammer" from "kassi_testperson1" with category "Items" and with transaction type "Lending"
    And I am logged in as "kassi_testperson2"
    And I am on the homepage
    When I follow "Hammer"
    And I follow "Borrow this item"
    And I fill in "Title" with "Borrowing hammer"
    And I fill in "Message" with "I want to borrow this item"
    And I press "Send message"
    Then I should see "Message sent" within ".flash-notifications"
    And I should see "Hammer" within "#listing-title"
    When I follow "inbox-link"
    Then I should see "I want to borrow this item"
    And I should see "to accept the request"
    When I click ".user-menu-toggle"
    When I follow "Log out"
    And I log in as "kassi_testperson1"
    And I follow "inbox-link"
    Then I should see "Accept"
    When I follow "Borrowing hammer"
    Then I should see "Accept"
    When the system processes jobs
    Then "kassi_testperson1@example.com" should have 1 email
    When "4" days have passed
    And the system processes jobs
    Then "kassi_testperson1@example.com" should have 2 emails
    When I open the email with subject "Remember to accept or reject a request"
    Then I should see "You have not yet accepted or rejected the request" in the email body
    When "4" days have passed
    Then "kassi_testperson1@example.com" should have 2 emails
    When "8" days have passed
    And the system processes jobs
    Then "kassi_testperson1@example.com" should have 3 emails
    When "100" days have passed
    And the system processes jobs
    Then "kassi_testperson1@example.com" should have 3 emails
    And return to current time
  
  @javascript
  Scenario: Borrowing an item with invalid information
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |
    And there is a listing with title "Hammer" from "kassi_testperson1" with category "Items" and with transaction type "Lending"
    And I am logged in as "kassi_testperson2"
    And I am on the homepage
    When I follow "Hammer"
    And I follow "Borrow this item"
    And I press "Send message"
    Then I should see "This field is required."
  
  @javascript  
  Scenario: Requesting an item without logging in and then logging in
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |
    Given there is a listing with title "Hammer" from "kassi_testperson1" with category "Items" and with transaction type "Lending"
    And I am on the homepage
    When I follow "Hammer"
    And I follow "Borrow this item"
    Then I should see "You must log in to Sharetribe to send a message to another user." within ".flash-notifications"
    And I should see "Log in to Sharetribe" within "h1"
    When I log in as "kassi_testperson2"
    Then I should see "This message is private"
  
  @javascript  
  Scenario: Trying to request an item without logging in and then logging in as the item owner
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |
    Given there is a listing with title "Hammer" from "kassi_testperson1" with category "Items" and with transaction type "Lending"
    And I am on the homepage
    When I follow "Hammer"
    And I follow "Borrow this item"
    Then I should see "You must log in to Sharetribe to send a message to another user." within ".flash-notifications"
    And I should see "Log in to Sharetribe" within "h1"
    When I log in as "kassi_testperson1"
    Then I should see "You cannot send a message to yourself" within ".flash-notifications"
    And I should see "Hammer"
