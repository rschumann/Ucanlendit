# encoding: UTF-8

include ApplicationHelper
include PeopleHelper
include ListingsHelper
include TruncateHtmlHelper

class PersonMailer < ActionMailer::Base
  
  # Enable use of method to_date.
  require 'active_support/core_ext'
  
  require "truncate_html"
  
  DEFAULT_TIME_FOR_COMMUNITY_UPDATES = 7.days
  
  default :from => APP_CONFIG.sharetribe_mail_from_address
  
  layout 'email'

  add_template_helper(EmailTemplateHelper)

  def community_specific_sender(com=nil)
    community = com || @current_community
    if community && community.custom_email_from_address
      community.custom_email_from_address
    else
      APP_CONFIG.sharetribe_mail_from_address
    end
  end

  def conversation_status_changed(conversation, community)
    @email_type =  (conversation.status == "accepted" ? "email_when_conversation_accepted" : "email_when_conversation_rejected")
    set_up_urls(conversation.other_party(conversation.listing.author), community, @email_type)
    @conversation = conversation

    if community.payments_in_use?
      @payment_url = community.payment_gateway.new_payment_url(@recipient, @conversation, @recipient.locale, @url_params)
    end

    mail(:to => @recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => t("emails.conversation_status_changed.your_#{Listing.opposite_type(conversation.listing.direction)}_was_#{conversation.status}"))
  end
  
  def new_message_notification(message, community)
    @email_type =  "email_about_new_messages"
    set_up_urls(message.conversation.other_party(message.sender), community, @email_type)
    @message = message
    sending_params = {:to => @recipient.confirmed_notification_emails_to,
         :subject => t("emails.new_message.you_have_a_new_message", :sender_name => message.sender.name(community)),
         :from => community_specific_sender(community)}
    
    mail(sending_params)
  end
  
  def new_payment(payment, community)
    @email_type =  "email_about_new_payments"
    @payment = payment
    set_up_urls(@payment.recipient, community, @email_type)
    mail(:to => @recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => t("emails.new_payment.new_payment"))
  end

  def braintree_new_payment(payment, community)
    @email_type =  "email_about_new_payments"
    @payment = payment

    @service_fee = PaymentMath.service_fee(@payment.sum_cents, community.commission_from_seller).to_f / 100
    @you_get = PaymentMath::SellerCommission.seller_gets(@payment.sum_cents, community.commission_from_seller).to_f / 100

    set_up_urls(@payment.recipient, community, @email_type)
    mail(:to => @recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => t("emails.new_payment.new_payment"))
  end
  
  def receipt_to_payer(payment, community)
    @email_type =  "email_about_new_payments"
    @payment = payment
    set_up_urls(@payment.payer, community, @email_type)
    mail(:to => @recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => t("emails.receipt_to_payer.receipt_of_payment"))
  end

  def braintree_receipt_to_payer(payment, community)
    @email_type =  "email_about_new_payments"
    @payment = payment
    set_up_urls(@payment.payer, community, @email_type)
    mail(:to => @recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => t("emails.receipt_to_payer.receipt_of_payment"))
  end
  
  def transaction_confirmed(conversation, community)
    @email_type =  "email_about_completed_transactions"
    @conversation = conversation
    set_up_urls(@conversation.offerer, community, @email_type)
    mail(:to => @recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => t("emails.transaction_confirmed.request_marked_as_#{@conversation.status}"))
  end

  def escrow_canceled_to(conversation, community, to)
    @email_type =  "email_about_canceled_escrow"
    @conversation = conversation
    set_up_urls(@conversation.offerer, community, @email_type)
    mail(:to => to,
         :from => community_specific_sender(community),
         :subject => t("emails.escrow_canceled.subject")) do |format|
      format.html { render "escrow_canceled" }
    end
  end

  def escrow_canceled(conversation, community)
    escrow_canceled_to(conversation, community, conversation.offerer.confirmed_notification_emails_to)
  end

  def admin_escrow_canceled(conversation, community)
    escrow_canceled_to(conversation, community, community.admin_emails.join(","))
  end
  
  def new_testimonial(testimonial, community)
    @email_type =  "email_about_new_received_testimonials"
    set_up_urls(testimonial.receiver, community, @email_type)
    @testimonial = testimonial
    mail(:to => @recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => t("emails.new_testimonial.has_given_you_feedback_in_kassi", :name => @testimonial.author.name(community)))
  end
  
  def new_badge(badge, community)
    @email_type = "email_about_new_badges"
    set_up_urls(badge.person, community, @email_type)
    @badge = badge
    @badge_name = t("people.profile_badge.#{@badge.name}")
    mail(:to => @recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => t("emails.new_badge.you_have_achieved_a_badge", :badge_name => @badge_name))
  end
  
  # Remind users of conversations that have not been accepted or rejected
  # NOTE: the not_really_a_recipient is at the same spot in params
  # to keep the call structure similar for reminder mails
  # but the actual recipient is always the listing author.
  def accept_reminder(conversation, not_really_a_recipient, community)
    @email_type = "email_about_accept_reminders"
    set_up_urls(conversation.listing.author, community, @email_type)
    @conversation = conversation
    mail(:to => @recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => t("emails.accept_reminder.remember_to_accept_#{@conversation.discussion_type}", :sender_name => @conversation.other_party(@recipient).name(community)))
  end
  
  # Remind users to pay
  def payment_reminder(conversation, recipient, community)
    @email_type = "email_about_payment_reminders"
    set_up_urls(conversation.payment.payer, community, @email_type)
    @conversation = conversation
    mail(:to => @recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => t("emails.payment_reminder.remember_to_pay", :listing_title => @conversation.listing.title))
  end

  # Remind user to fill in payment details
  def payment_settings_reminder(listing, recipient, community)
    set_up_urls(recipient, community)
    @listing = listing
    @recipient = recipient

    if community.payments_in_use?
      @payment_settings_link = community.payment_gateway.settings_url(@recipient, @recipient.locale, @url_params)
    end

    mail(:to => recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => t("emails.payment_settings_reminder.remember_to_add_payment_details")) do |format|
            format.html {render :locals => {:skip_unsubscribe_footer => true} }
    end
  end

  # Braintree account was approved (via Webhook)
  def braintree_account_approved(recipient, community)
    set_up_urls(recipient, community)
    @recipient = recipient

    mail(:to => recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => t("emails.braintree_account_approved.account_ready")) do |format|
            format.html {render :locals => {:skip_unsubscribe_footer => true} }
    end
  end
  
  # Remind users of conversations that have not been accepted or rejected
  def confirm_reminder(conversation, recipient, community)
    @email_type = "email_about_confirm_reminders"
    set_up_urls(conversation.requester, community, @email_type)
    @conversation = conversation
    escrow = community.payment_gateway && community.payment_gateway.hold_in_escrow
    template = escrow ? "confirm_reminder_escrow" : "confirm_reminder"
    mail(:to => @recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => t("emails.confirm_reminder.remember_to_confirm_request")) do |format|
      format.html { render template }
    end
  end
  
  # Remind users to give feedback
  def testimonial_reminder(conversation, recipient, community)
    @email_type = "email_about_testimonial_reminders"
    set_up_urls(recipient, community, @email_type)
    @conversation = conversation
    @other_party = @conversation.other_party(@recipient)
    mail(:to => @recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => t("emails.testimonial_reminder.remember_to_give_feedback_to", :name => @other_party.name))
  end
  
  def new_comment_to_own_listing_notification(comment, community)
    @email_type = "email_about_new_comments_to_own_listing"
    set_up_urls(comment.listing.author, community, @email_type)
    @comment = comment
    mail(:to => @recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => t("emails.new_comment.you_have_a_new_comment", :author => @comment.author.name(community)))
  end
  
  def new_comment_to_followed_listing_notification(comment, recipient, community)
    set_up_urls(recipient, community)
    @comment = comment
    mail(:to => @recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => t("emails.new_comment.listing_you_follow_has_a_new_comment", :author => @comment.author.name(community)))
  end
  
  def new_update_to_followed_listing_notification(listing, recipient, community)
    set_up_urls(recipient, community)
    @listing = listing
    mail(:to => @recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => t("emails.new_update_to_listing.listing_you_follow_has_been_updated"))
  end
  
  def invitation_to_kassi(invitation)
    @invitation = invitation
    I18n.locale = @invitation.inviter.locale
    @invitation_code_required = @invitation.community.join_with_invite_only
    set_up_urls(nil, @invitation.community)
    @url_params[:locale] = @invitation.inviter.locale
    subject = t("emails.invitation_to_kassi.you_have_been_invited_to_kassi", :inviter => @invitation.inviter.name(@invitation.community), :community => @invitation.community.full_name_with_separator(@invitation.inviter.locale))
    mail(:to => @invitation.email, 
         :from => community_specific_sender(@invitation.community),
         :subject => subject, 
         :reply_to => @invitation.inviter.email)
  end
  
  # A message from the community admin to a single community member
  def community_member_email(sender, recipient, email_subject, email_content, community)
    @email_type = "email_from_admins"
    set_up_urls(recipient, community, @email_type)
    @email_content = email_content
    @no_recipient_name = true
    mail(:to => @recipient.confirmed_notification_emails_to, 
         :from => community_specific_sender(community),
         :subject => email_subject, 
         :reply_to => "\"#{sender.name(community)}\"<#{sender.confirmed_notification_email_to}>")
  end
  
  # A custom message to a community starter
  def community_starter_email(person, community)
    @email_type = "email_from_admins"
    set_up_urls(person, community, @email_type)
    @community = community
    @no_recipient_name = true
    # This check needs to be here because this method is currently
    # usually called directly from console.
    if @recipient.should_receive?("email_from_admins")
      mail(:to => @recipient.confirmed_notification_emails_to, 
           :from => community_specific_sender(community),
           :subject => t("emails.community_starter_email.subject")) do |format|
        format.html { render "community_starter_email_#{@recipient.locale}" }
      end
    end
  end
  
  # Used to send notification to Sharetribe admins when somebody
  # gives feedback on Sharetribe
  def new_feedback(feedback, community)
    @feedback = feedback

    @feedback.email = if feedback.author then
      feedback.author.confirmed_notification_email_to
    else
      @feedback.email
    end

    @current_community = community
    subject = "New #unanswered #feedback from #{@current_community.name('en')} community from user #{feedback.author.try(:name)} "
    mail_to = APP_CONFIG.feedback_mailer_recipients + (@current_community.feedback_to_admin? ? ", #{@current_community.admin_emails.join(",")}" : "")
    mail(:to => mail_to,
         :from => community_specific_sender(community),
         :subject => subject, 
         :reply_to => @feedback.email)
  end
  
  # Used to send notification to admins when somebody
  # wants to contact them through the form in the network page
  def contact_request_notification(contact_request)
    @contact_request = contact_request
    subject = "New contact request by #{@contact_request.email}"
    mail(:to => APP_CONFIG.feedback_mailer_recipients, :subject => subject) do |format|
      format.html {render :layout => false }
    end
  end
  
  # Automatic reply to people who try to contact us via Dashboard
  def reply_to_contact_request(contact_request)
    @contact_request = contact_request
    @country_manager = CountryManager.find_by_country(@contact_request.country) || CountryManager.find_by_country("global")
    #@country_manager ||= CountryManager.find_by_country("global")
    set_locale @country_manager.locale
    email_from = "#{@country_manager.given_name} #{@country_manager.family_name} <#{@country_manager.email}>"
    mail(:to => @contact_request.email, :subject => @country_manager.subject_line, :from => email_from) do |format|
      format.html { render :layout => false }
    end
  end
  
  
  
  # Old layout
  
  def new_member_notification(person, community_domain, email)
    @community = Community.find_by_domain(community_domain)
    @no_settings = true
    @person = person
    @email = email
    mail(:to => @community.admin_emails, 
         :from => community_specific_sender(@community),
         :subject => "New member in #{@community.name} Sharetribe")
  end

  def email_confirmation(email, host, com=nil)
    community = com || Community.find_by_domain(host)
    @no_settings = true
    @resource = email.person
    @confirmation_token = email.confirmation_token
    @host = host
    email.update_attribute(:confirmation_sent_at, Time.now)
    mail(:to => email.address, 
         :from => community_specific_sender(com),
         :subject => t("devise.mailer.confirmation_instructions.subject"), 
         :template_path => 'devise/mailer', 
         :template_name => 'confirmation_instructions')
  end
  
  def reset_password_instructions(person, email_address, community)
    set_up_urls(nil, community) # Using nil as recipient, as we don't want auth token here.
    @person = person
    @no_settings = true
    mail(:to => email_address,
         :from => community_specific_sender(@community),
         :subject => t("devise.mailer.reset_password_instructions.subject")) do |format|
       format.html { render :layout => false }
     end
  end
  
  def community_updates(recipient, community)
    @community = community
    @recipient = recipient
    
    unless @recipient.member_of?(@community)
      logger.info "Trying to send community updates to a person who is not member of the given community. Skipping."
      return
    end
    
    set_locale @recipient.locale
    I18n.locale = @recipient.locale  #This was added so that listing share_types get correct translation

    @time_since_last_update = t("timestamps.days_since", 
        :count => time_difference_in_days(@recipient.community_updates_last_sent_at || 
        DEFAULT_TIME_FOR_COMMUNITY_UPDATES.ago))
    @auth_token = @recipient.new_email_auth_token
    @url_params = {}
    @url_params[:host] = "#{@community.full_domain}"
    @url_params[:locale] = @recipient.locale
    @url_params[:ref] = "weeklymail"
    @url_params[:auth] = @auth_token
    @url_params.freeze # to avoid accidental modifications later
    
    latest = @recipient.community_updates_last_sent_at || DEFAULT_TIME_FOR_COMMUNITY_UPDATES.ago
    
    @listings = @community.listings.currently_open.where("created_at > ?", latest).order("created_at DESC").visible_to(@recipient, @community).limit(10)
  
    if @listings.size < 1
      logger.info "There are no new listings in community #{@community.name(@recipient.locale)} since that last update for #{@recipient.id}"
      return
    end
    
    @title_link_text = t("emails.community_updates.title_link_text", 
          :community_name => @community.full_name(@recipient.locale))
    subject = t("emails.community_updates.update_mail_title", :title_link => @title_link_text)
    
    if APP_CONFIG.mail_delivery_method == "postmark"
      # Postmark doesn't support bulk emails, so use Sendmail for this
      delivery_method = :sendmail
    else
      delivery_method = APP_CONFIG.mail_delivery_method.to_sym unless Rails.env.test?
    end
    
    mail(:to => @recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(community),
         :subject => subject,
         :delivery_method => delivery_method) do |format|
      format.html { render :layout => false }
    end
  end
  
  def newsletter(recipient, newsletter_filename)
    
    @recipient = recipient
    set_locale recipient.locale
    
    @newsletter_path = "newsletters/#{newsletter_filename}.#{@recipient.locale}.html"
    @newsletter_content = File.read("public/#{@newsletter_path}")
    
    @community = recipient.communities.first # We pick random community to point the settings link to
    
    @url_base = "#{@community.full_url}"
    @settings_url = "#{@url_base}#{notifications_person_settings_path(:person_id => recipient.id, :locale => @recipient.locale)}"
    
    mail(:to => @recipient.confirmed_notification_emails_to, 
         :from => community_specific_sender(@community),
         :subject => t("emails.newsletter.occasional_newsletter_title")) do |format|
      format.html { render :layout => "newsletter" }
    end
  end
  
  # This is used by console script that creates a list of user accounts and sends an email to all
  # Currently only in spanish, as not yet needed in other languages
  def automatic_account_created(recipient, password)
    @no_settings = true
    @username = recipient.username
    @given_name = recipient.given_name
    @password = password
    subject = "Tienes una cuenta creada para la comunidad Diseño UDD de Sharetribe"
    
    if APP_CONFIG.mail_delivery_method == "postmark"
      # Postmark doesn't support bulk emails, so use Sendmail for this
      delivery_method = :sendmail
    else
      delivery_method = APP_CONFIG.mail_delivery_method.to_sym
    end
    
    mail(:to => recipient.confirmed_notification_emails_to, :subject => subject, :reply_to => "diego@sharetribe.com", :delivery_method => delivery_method)
  end
  
  # This method can send any plain text mail where subject and mail contents are given in parameters.
  # Only thing added to contents is "Hi (user's name),"
  def open_content_message(recipient, subject, mail_content, default_locale="en")
    @no_settings = true
    @recipient = recipient
    @subject = subject
    if @recipient.locale == "ca" || @recipient.locale == "es-ES"
      if mail_content["es"].present?
        # special change for ca and es-ES 
        # because those probably don't have separate texts in neaer future
        # but we probably have spanish, so it makes more sense as fallback than english.
        default_locale = "es"
      end
    end
    
    # Set mail contents, which can be a string or hash containing contents for many languages
    # For example:
    # {"en" => {"subject" => "changes coming", "body" => "We're doing new stuff\nCheck it out at..."}, "fi" => {etc.}}    
    if mail_content.class == String
      @mail_content = mail_content
    elsif mail_content.class == Hash
      if mail_content[@recipient.locale].present?
        @mail_content = mail_content[@recipient.locale]["body"]
        @subject = mail_content[@recipient.locale]["subject"]
        set_locale @recipient.locale
      elsif default_locale && mail_content[default_locale].present?
        @mail_content = mail_content[default_locale]["body"]
        @subject = mail_content[default_locale]["subject"]
        set_locale default_locale
      else
        throw "No content with user's locale #{recipient.locale}, and no working default provided."
      end    
    else
      throw "Unknown type for mail_content"
    end

    # disable escaping since this is currently always coming from trusted source.
    @mail_content = @mail_content.html_safe
    
    mail(:to => @recipient.confirmed_notification_emails_to, :subject => @subject) do |format|
      format.text { render :layout => false }
    end
  end
  
  def self.deliver_old_style_community_updates
    Community.find_each do |community|
      if community.created_at < 1.week.ago && community.listings.size > 5 && community.automatic_newsletters
        community.members.each do |member|
          if member.should_receive?("community_updates")
            begin
              PersonMailer.old_style_community_updates(member, community).deliver
            rescue => e
              # Catch the exception and continue sending the news letter
              ApplicationHelper.send_error_notification("Error sending mail for weekly community updates: #{e.message}", e.class)
            end
          end
        end
      end
    end
  end
  
  # This task is expected to be run with daily or hourly scheduling
  # It looks through all users and send email to those who want it now 
  def deliver_community_updates
    Person.find_each do |person|
      if person.should_receive_community_updates_now?
        person.communities.each do |community|
          if community.has_new_listings_since?(person.community_updates_last_sent_at || DEFAULT_TIME_FOR_COMMUNITY_UPDATES.ago)
            begin
              PersonMailer.community_updates(person, community).deliver
            rescue => e
              # Catch the exception and continue sending emails
            puts "Error sending mail to #{person.confirmed_notification_emails} community updates: #{e.message}"
            ApplicationHelper.send_error_notification("Error sending mail to #{person.confirmed_notification_emails} community updates: #{e.message}", e.class)
            end
          end
        end
        # After sending updates for all communities that had something new, update the time of last sent updates to Time.now.
        person.update_attribute(:community_updates_last_sent_at, Time.now)
      end
    end
  end
  
  def self.deliver_newsletters(newsletter_filename)
    unless File.exists?("public/newsletters/#{newsletter_filename}.en.html")
      puts "Can't find the newsletter file in english (public/newsletters/#{newsletter_filename}.en.html) Maybe you mistyped the first part of filename?"
      return
    end
    
    Person.find_each do |person|
      if person.should_receive?("email_newsletters")
        begin
          if File.exists?("public/newsletters/#{newsletter_filename}.#{person.locale}.html")
            PersonMailer.newsletter(person, newsletter_filename).deliver
          else
            logger.debug "Skipping sending newsletter to #{person.username}, because his locale is #{person.locale} and that file was not found."
          end
        rescue => e
          # Catch the exception and continue sending the newsletter
          ApplicationHelper.send_error_notification("Error sending newsletter for #{person.username}: #{e.message}", e.class)
        end
      end 
    end;"Newsletters sent"
  end  
  
  def self.deliver_open_content_messages(people_array, subject, mail_content, default_locale="en", verbose=false, addresses_to_skip=[])
    people_array.each do |person|
      # only send mail to people whose profile is active and not asked to be skipped
      if person.active && ! person.confirmed_notification_emails.any? { |notification_email| addresses_to_skip.include?(notification_email) }
        begin
          PersonMailer.open_content_message(person, subject, mail_content, default_locale).deliver
        rescue => e
          ApplicationHelper.send_error_notification("Error sending open content email: #{e.message}", e.class)
        end
        if verbose #main intention of this is to get feedback while sending mass emails from console.
          print "."; STDOUT.flush
        end
      else
        print "s" if verbose # (skipped)
      end
    end
    puts "\nSending mails finished" if verbose
    
  end
  
  def welcome_email(person, community, regular_email=nil)
    @recipient = person
    set_locale @recipient.locale
    @current_community = community
    @regular_email = regular_email
    @url_params = {}
    @url_params[:host] = "#{@current_community.full_domain}"
    @url_params[:auth] = @recipient.new_email_auth_token
    @url_params[:locale] = @recipient.locale
    @url_params[:ref] = "welcome_email"
    @url_params.freeze # to avoid accidental modifications later
        
    if @recipient.has_admin_rights_in?(@current_community) && !@regular_email
      subject = t("emails.welcome_email.congrats_for_creating_community", :community => @current_community.full_name(@recipient.locale))
    else
      subject = t("emails.welcome_email.subject", :community => @current_community.full_name(@recipient.locale), :person => person.given_name_or_username)
    end
    mail(:to => @recipient.confirmed_notification_emails_to,
         :from => community_specific_sender(@community),
         :subject => subject) do |format|
      format.html { render :layout => false }
    end
  end
  
  # A message from the community admin to all the community members
  def self.community_member_emails(sender, community, email_subject, email_content, email_locale)
    community.members.each do |recipient|
      if recipient.should_receive?("email_from_admins") && (email_locale.eql?("any") || recipient.locale.eql?(email_locale))
        begin
          community_member_email(sender, recipient, email_subject, email_content, community).deliver
        rescue => e
          # Catch the exception and continue sending the emails
          ApplicationHelper.send_error_notification("Error sending email to all the members of community #{community.full_name(email_locale)}: #{e.message}", e.class)
        end
      end
    end
  end
  
  # A custom message to all the community starters
  def self.community_starter_emails
    CommunityMembership.where(:admin => true).each do |community_membership|
      begin
        community_starter_email(community_membership.person, community_membership.community).deliver
      rescue => e
        # Catch the exception and continue sending the emails
        ApplicationHelper.send_error_notification("Error sending email to all community starters: #{e.message}", e.class)
      end
    end
  end
  
  private
  
  def set_up_urls(recipient, community, ref="email")
    @community = community
    @url_params = {}
    @url_params[:host] = community.full_domain
    @url_params[:ref] = ref
    if recipient
      @recipient = recipient
      @url_params[:auth] = @recipient.new_email_auth_token
      @url_params[:locale] = @recipient.locale
      set_locale @recipient.locale
    end
  end

end