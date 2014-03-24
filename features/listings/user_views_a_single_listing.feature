Feature: User views a single listing
  In order to value
  As a role
  I want feature

  Background:
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |

  @javascript
  @only_without_asi
  Scenario: User views a listing that he is allowed to see
    And there is a listing with title "Massage" from "kassi_testperson1" with category "Services" and with transaction type "Requesting"
    And I am on the home page
    When I follow "Massage"
    Then I should see "Massage"
    When I am logged in as "kassi_testperson1"
    And I have "2" testimonials with grade "1"
    And I am on the home page
    And I follow "Massage"
    Then I should see "Feedback"
    And I should see "100%"
    And I should see "(2/2)"
  
  @javascript
  @phantomjs_skip
  Scenario: User sees the avatar in listing page
    Given I am logged in as "kassi_testperson1"
    And there is a listing with title "Massage" from "kassi_testperson1" with category "Services" and with transaction type "Requesting"
    When I click ".user-menu-toggle"
    When I follow "Settings"
    And I attach a valid image file to "avatar_file"
    And I press "Save information"
    And I go to the home page
    And I follow "Massage"
    Then I should not see "Add profile picture"
  
  @javascript
  Scenario: User tries to view a listing restricted viewable to community members without logging in
    Given I am not logged in
    And there is a listing with title "Massage" from "kassi_testperson1" with category "Services" and with transaction type "Requesting"
    And privacy of that listing is "private"
    And I am on the home page
    When I go to the listing page
    Then I should see "You must log in to view this content"
  
  @subdomain2
  @javascript
  Scenario: User tries to view a listing from another community
    Given I am not logged in
    And there is a listing with title "Massage" from "kassi_testperson1" with category "Services" and with transaction type "Requesting"
    And that listing belongs to community "test"
    And I am on the home page
    When I go to the listing page
    Then I should see "This content is not available in this community."
  
  @javascript
  Scenario: User belongs to multiple communities, adds listing in one and sees it in another
    Given I am not logged in
    And there is a listing with title "Massage" from "kassi_testperson1" with category "Services" and with transaction type "Requesting"
    And privacy of that listing is "private"
    And I am on the home page
    When I go to the listing page
    Then I should see "You must log in to view this content"
  
  @javascript
  Scenario: User views listing created 
    Given I am not logged in
    And there is a listing with title "Massage" from "kassi_testperson1" with category "Services" and with transaction type "Requesting"
    When I go to the listing page
    Then I should not see "Listing created"
    When listing publishing date is shown in community "test"
    And I go to the listing page
    Then I should see "Listing created"
