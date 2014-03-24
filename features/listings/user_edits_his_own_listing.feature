Feature: User edits his own listing
  In order to change the content of a listing
  As the creator of the listing
  I want to be able to edit the listing

  @phantomjs_skip
  @javascript
  Scenario: User edits an item request with image
    Given there are following users:
      | person | 
      | kassi_testperson1 |
    And there is a listing with title "Hammer" from "kassi_testperson1" with category "Items" and with transaction type "Requesting"
    And I am logged in as "kassi_testperson2"
    And I follow "Hammer"
    And I click ".user-menu-toggle"
    And I follow "Log out"
    And I log in as "kassi_testperson1"
    When I follow "Hammer"
    And I follow "Edit listing"
    And the "listing_title" field should contain "Hammer"
    And the "description" field should contain "test"
    And I fill in "listing_title" with "Sledgehammer"
    And I fill in "listing_description" with "My description"
    And I attach a valid image file to "listing_listing_images_attributes_0_image"
    And I press "Save listing"
    And the system processes jobs
    Then I should see "Sledgehammer" within "#listing-title"
    And I should see the image I just uploaded
    When I follow "Edit listing"
    Then I should see the image I just uploaded
    And I follow "Remove image"
    And wait for 5 seconds
    And I press "Save listing"
    Then I should not see the image I just uploaded

  @javascript
  Scenario: User edits an item request without image
    Given there are following users:
      | person | 
      | kassi_testperson1 |
    And there is a listing with title "Hammer" from "kassi_testperson1" with category "Items" and with transaction type "Requesting"
    And I am logged in as "kassi_testperson2"
    And I follow "Hammer"
    And I click ".user-menu-toggle"
    And I follow "Log out"
    And I log in as "kassi_testperson1"
    When I follow "Hammer"
    And I follow "Edit listing"
    And the "listing_title" field should contain "Hammer"
    And the "description" field should contain "test"
    And I fill in "listing_title" with "Sledgehammer"
    And I fill in "listing_description" with "My description"
    And I press "Save listing"
    And the system processes jobs
    Then I should see "Sledgehammer" within "#listing-title"
  
  @javascript
  Scenario: Trying to update an item request with invalid information
    Given there are following users:
      | person | 
      | kassi_testperson1 |
    And there is a listing with title "Hammer" from "kassi_testperson1" with category "Items" and with transaction type "Requesting"
    And I am logged in as "kassi_testperson1"
    When I follow "Hammer"
    And I follow "Edit listing" within "#listing-message-links"
    And I fill in "listing_title" with ""
    And I select "31" from "listing_valid_until_3i"
    And I select "December" from "listing_valid_until_2i"
    And I select "2014" from "listing_valid_until_1i"
    And I press "Save listing"
    Then I should see "This field is required." 
    And I should see "This date must be between current time and 6 months from now."  

  @javascript
  Scenario: Trying to update somebody else's listing
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |
    And there is a listing with title "Hammer" from "kassi_testperson1" with category "Items" and with transaction type "Requesting"
    And I am logged in as "kassi_testperson2"
    When I go to the edit listing page
    Then I should see "Only listing author can edit a listing"

  @javascript
  Scenario: Trying to update somebody else's listing as an admin
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |
    And there is a listing with title "Hammer" from "kassi_testperson1" with category "Items" and with transaction type "Requesting"
    And I am logged in as "kassi_testperson2"
    And "kassi_testperson2" is superadmin
    When I follow "Hammer"
    And I follow "Edit listing"
    And I fill in "listing_title" with "Sledgehammer"
    And I press "Save listing"
    Then I should see "Sledgehammer" within "#listing-title"
    And I should see "Listing updated successfully"
    
  @javascript
  Scenario: Trying to update somebody else's listing as an admin of the current community
    Given there are following users:
      | person | 
      | kassi_testperson1 |
      | kassi_testperson2 |
    And there is a listing with title "Hammer" from "kassi_testperson1" with category "Items" and with transaction type "Requesting"
    And I am logged in as "kassi_testperson2"
    And "kassi_testperson2" has admin rights in community "Test"
    When I follow "Hammer"
    And I follow "Edit listing"
    And I fill in "listing_title" with "Sledgehammer"
    And I press "Save listing"
    Then I should see "Sledgehammer" within "#listing-title"
    And I should see "Listing updated successfully"