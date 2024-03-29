Given /^there is a message "([^"]*)" from "([^"]*)" about that listing$/ do |message, sender|
  # Hard-coded to the first community. Change this if needed
  community = @listing.communities.first

  @conversation = Conversation.create!(:listing_id => @listing.id, 
                                      :title => message,
                                      :status => "pending", 
                                      :conversation_participants => { @listing.author.id => "false", @people[sender].id => "true"},
                                      :message_attributes => { :content => message, :sender_id => @people[sender].id },
                                      :community => community
                                      ) 
end

Given /^there is a reply "([^"]*)" to that message by "([^"]*)"$/ do |content, sender|
  @message = Message.create!(:conversation_id => @conversation.id, 
                            :sender_id => @people[sender].id, 
                            :content => content
                           )                                   
end

When /^I try to go to inbox of "([^"]*)"$/ do |person|
  visit received_person_messages_path(:locale => :en, :person_id => @people[person].id)
end

Then /^the status of the conversation should be "([^"]*)"$/ do |status|
  @conversation.status.should == status 
end

Given /^the (offer|request) is (accepted|rejected|confirmed|canceled)$/ do |listing_type, status|
  @conversation.update_attribute(:status, status)

  if listing_type == "request" && status =="accepted" && @conversation.community.payment_possible_for?(@conversation.listing)
    # In this case there should be a pending payment done when this got accepted.
    FactoryGirl.create(:payment, :conversation => @conversation, :recipient => @conversation.listing.author, :status => "pending", :sum => @conversation.listing.price)
  end
end

When /^there is feedback about that event from "([^"]*)" with grade "([^"]*)" and with text "([^"]*)"$/ do |feedback_giver, grade, text|
  participation = @conversation.participations.find_by_person_id(@people[feedback_giver].id)
  Testimonial.create!(:grade => grade, :author_id => @people[feedback_giver].id, :text => text, :participation_id => participation.id, :receiver_id => @conversation.other_party(@people[feedback_giver]).id)
end

Then /^I should see information about missing payment details$/ do
  find("#conversation-payment-details-missing").should be_visible
end

When(/^I skip feedback$/) do
  steps %Q{
    When I click "#do_not_give_feedback"
    And I press submit
  }
end