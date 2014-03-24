require 'spec_helper'

describe SettingsController do

  before(:each) do
    @community = FactoryGirl.create(:community)
    @request.host = "#{@community.domain}.lvh.me"
    @person = FactoryGirl.create(:person)

    FactoryGirl.create(:community_membership, :person => @person, :community => @community)
  end

  describe "#unsubscribe" do
    
    it "should unsubscribe the user from the email specified in parameters" do
      sign_in_for_spec(@person)
      @person.set_default_preferences
      @person.min_days_between_community_updates.should == 1

      get :unsubscribe, {:email_type => "community_updates", :person_id => @person.id}
      puts response.body
      response.status.should == 200
      @person.min_days_between_community_updates.should == 100000
    end
    
    it "should unsubscribe even if auth token is expired" do
      t = @person.new_email_auth_token
      AuthToken.find_by_token(t).update_attribute(:expires_at, 2.days.ago)
      @person.set_default_preferences
      @person.min_days_between_community_updates.should == 1
      
      get :unsubscribe, {:email_type => "community_updates", :person_id => @person.id, :auth => t}
      response.status.should == 302 #redirection to url withouth token in query string
      session[:expired_auth_token].should == t
      get :unsubscribe, {:email_type => "community_updates", :person_id => @person.id},
                        {:expired_auth_token => t}
      response.status.should == 200
      @person = Person.find(@person.id) # fetch again to refresh
      @person.min_days_between_community_updates.should == 100000
    end
    
    it "should not unsubscribe if no token provided" do
      @person.set_default_preferences
      @person.min_days_between_community_updates.should == 1
      
      get :unsubscribe, {:email_type => "community_updates", :person_id => @person.id}
      response.status.should == 401
      @person.min_days_between_community_updates.should == 1
    end
  end
end
