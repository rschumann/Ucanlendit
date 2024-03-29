require 'spec_helper'

describe BraintreeWebhooksController do
  before(:each) do
    @community = FactoryGirl.create(:community, :domain => "market.custom.org")
    FactoryGirl.create(:payment_gateway, :community => @community, :type => "BraintreePaymentGateway")

    # Refresh from DB
    @community.reload

    # Guard assert
    @community.braintree_in_use?.should be_true
  end

  describe "#hooks" do

    before(:each) do
      # Helpers for posting the hook
      @post_hook = ->(kind, id){
        signature, payload = BraintreeApi.webhook_testing_sample_notification(
          @community,
          kind,
          id
        )

        # Do
        post :hooks, :bt_signature => signature, :bt_payload => payload, :community_id => @community.id
      }
    end

    it "rescues from error" do
      # Prepare
      @person = FactoryGirl.create(:person, :id => "123abc")

      signature, payload = BraintreeApi.webhook_testing_sample_notification(
        @community,
        Braintree::WebhookNotification::Kind::SubMerchantAccountApproved,
        @person.id
      )

      post :hooks, :bt_signature => "#{signature}-invalid", :bt_payload => payload, :community_id => @community.id

      response.status.should == 400
    end

    describe "account creation hooks" do

      before(:each) do
        # Prepare
        @person = FactoryGirl.create(:person, :id => "123abc")
        @braintree_account = FactoryGirl.create(:braintree_account, :person => @person, :status => "pending")

        # Guard assert
        BraintreeAccount.find_by_person_id(@person.id).status.should == "pending"
      end

      it "listens for SubMerchantAccountApproved" do
        @post_hook.call(Braintree::WebhookNotification::Kind::SubMerchantAccountApproved, @person.id)
        BraintreeAccount.find_by_person_id(@person.id).status.should == "active"
      end

      it "listens for SubMerchantAccountDeclined" do
        @post_hook.call(Braintree::WebhookNotification::Kind::SubMerchantAccountDeclined, @person.id)
        BraintreeAccount.find_by_person_id(@person.id).status.should == "suspended"
      end
    end

    describe "transaction disbursed" do
      before(:each) do
        # Prepare
        @conversation = FactoryGirl.create(:conversation)
        @payment = FactoryGirl.create(:payment, :status => "paid", :braintree_transaction_id => "123abc", :type => "BraintreePayment", :conversation => @conversation, :sum_cents => 1000, :currency => "EUR")
        Payment.find_by_braintree_transaction_id("123abc").status.should == "paid"
      end

      it "listens for TransactionDisbursed" do
        @post_hook.call(Braintree::WebhookNotification::Kind::TransactionDisbursed, @payment.braintree_transaction_id)
        Payment.find_by_braintree_transaction_id(@payment.braintree_transaction_id).status.should == "disbursed"
      end
    end
  end
end