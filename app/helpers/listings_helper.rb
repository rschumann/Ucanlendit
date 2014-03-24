module ListingsHelper

  # Class is selected if conversation type is currently selected
  def get_map_tab_class(tab_name)
    current_tab_name = action_name || "map_view"
    "inbox_tab_#{current_tab_name.eql?(tab_name) ? 'selected' : 'unselected'}"
  end

  # Removes extra characters from datetime_select field
  def clear_datetime_select(&block)
    time = "</div><div class='date_select_time_container'><div class='datetime_select_time_label'>#{t('listings.form.departure_time.at')}:</div>"
    colon = "</div><div class='date_select_time_container'><div class='datetime_select_colon_label'>:</div>"
    haml_concat capture_haml(&block).gsub(":", "#{colon}").gsub("&mdash;", "#{time}").gsub("\n", '').html_safe
  end

  # Class is selected if listing type is currently selected
  def get_listing_tab_class(tab_name)
    current_tab_name = params[:type] || "list_view"
    "inbox_tab_#{current_tab_name.eql?(tab_name) ? 'selected' : 'unselected'}"
  end

  def visibility_array
    array = []
    Listing::VALID_VISIBILITIES.each do |visibility|
      if visibility.eql?("this_community")
        array << [t(".#{visibility}", :community => @current_community.name(I18n.locale)), visibility]
      else
        array << [t(".#{visibility}"), visibility]
      end
    end
    return array
  end

  def privacy_array
    Listing::VALID_PRIVACY_OPTIONS.collect { |option| [t(".#{option}"), option] }
  end

  def listed_listing_title(listing)
    listing.transaction_type.display_name(I18n.locale) + ": #{listing.title}"
  end

  def transaction_type_url(listing, view)
    root_path(:transaction_type => listing.transaction_type.id, :view => view)
  end

  def localized_category_label(category)
    return nil if category.nil?
    return category.display_name(I18n.locale).capitalize
  end

  def localized_transaction_type_label(transaction_type)
    return nil if transaction_type.nil?
    return transaction_type.display_name(I18n.locale).capitalize
  end

  def localized_listing_type_label(listing_type_string)
    return nil if listing_type_string.nil?
    return t("listings.show.#{listing_type_string}", :default => listing_type_string.capitalize)
  end

  def listing_form_menu_titles(community_attribute_values)
    titles = {
      "category" => t(".select_category"),
      "subcategory" => t(".select_subcategory"),
      "transaction_type" => t(".select_transaction_type")
    }
  end

  def major_currencies(hash)
    hash.inject([]) do |array, (id, attributes)|
      array ||= []
      array << [attributes[:iso_code]]
      array.sort
    end.compact.flatten
  end

  def price_as_text(listing)
    money_without_cents_and_with_symbol(listing.price).upcase +
    unless listing.quantity.blank? then " / #{listing.quantity}" else "" end +
    if @current_community.vat then " " + t("listings.displayed_price.price_excludes_vat") else "" end
  end

  def is_image_processing?(listing)
    with_first_listing_image(listing) do |first_image|
      first_image.image_processing
    end
  end

  def has_images?(listing)
    !listing.listing_images.empty?
  end

  def with_image_frame(listing, &block)
    if self.has_images?(listing) then
      first_image = listing.listing_images.first
      if first_image.image_processing then
        block.call(:image_processing, nil)
      else
        block.call(:image_ok, first_image)
      end
    elsif listing.description.blank? then
      block.call(:no_description, nil)
    end
  end

  def aspect_ratio_class(image)
    aspect_ratio = 3/2.to_f
    if image.correct_size? aspect_ratio
      "correct-ratio"
    elsif image.too_narrow? aspect_ratio
      "too-narrow"
    else
      "too-wide"
    end
  end

  def with_quantity_and_vat_text(community, listing, &block)
    buffer = []
    unless listing.quantity.blank?
      buffer.push("/ #{@listing.quantity}")
    end

    if community.vat
      buffer.push(t(".price_excludes_vat"))
    end

    block.call(buffer.join(" ")) unless buffer.empty?
  end
end
