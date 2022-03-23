class Address < ApplicationRecord
  #validates_presence_of :name
  #validates_presence_of :address
  #validates_presence_of :state, :if => :state_required?
  #validates_presence_of :country
  #validates_format_of :phone, :with => /^[0-9\-\+ ]*$/
  #validates_format_of :email, :with => /^[^@]*@.*\.[^\.]*$/, :message => 'is invalid. Please enter an address in the format of you@company.com'
  #validates_presence_of :phone, :message => ' is required.'

  #-------------------------------------------------------------------------------------------------
  normalize_attributes :name, :city, :state, :postal_code, :country
  normalize_attribute  :address, :with => [:cleanlines, :strip]

  #-------------------------------------------------------------------------------------------------
  # Country code

  def country_alpha2=(code)
    if code.blank?
      write_attribute(:country, nil)
      write_attribute(:country_alpha2, nil)
      write_attribute(:country_alpha3, nil)

    elsif (country = Carmen::Country.alpha_2_coded(code))
      # Only set it if it's a recognized country code
      write_attribute(:country, country.name)
      write_attribute(:country_alpha2, code)
    end
  end

  # Aliases
  def country_code
    country_alpha2
  end
  def country_code=(code)
    self.country_alpha2 = code
  end
  def state_code
    state
  end

  def carmen_country
    Carmen::Country.alpha_2_coded(country_alpha2)
  end

  def carmen_state
    if (country = carmen_country)
      Address.states_for_country(country).coded(state_code)
    end
  end

  #-------------------------------------------------------------------------------------------------
  # Country name

  def country=(name)
    if name.blank?
      write_attribute(:country, nil)
      write_attribute(:country_alpha2, nil)
      write_attribute(:country_alpha3, nil)
    else
      name = recognize_country_name_alias(name)
      if (country = Carmen::Country.named(name))
        write_attribute(:country,        country.name)
        write_attribute(:country_alpha2, country.alpha_2_code)
        write_attribute(:country_alpha3, country.alpha_3_code)
      else
        write_attribute(:country, nil)
        write_attribute(:country_alpha2, nil)
        write_attribute(:country_alpha3, nil)
      end
    end
  end

  def recognize_country_name_alias(name)
    name = case name
    when 'USA'
    when 'The Democratic Republic of the Congo', 'Democratic Republic of the Congo'
      'Congo, the Democratic Republic of the'
    when 'Republic of Macedonia', 'Macedonia, Republic of', 'Macedonia'
      'Macedonia, Republic of'
    else
      name
    end
  end

  # This should not be different from the value stored in the country attribute, but allows you to
  # look it up just to make sure they match (or to update country field to match this).
  def country_name_from_code
    if (country = Carmen::Country.alpha_2_coded(country_alpha2))
      country.name
    end
  end

  # Aliases
  def country_name
    country
  end
  def country_name=(name)
    self.country = name
  end

  #=================================================================================================
  # State/province options for country

  # This is useful if want to list the state options allowed for a country in a select box and
  # restrict entry to only officially listed state options.
  # It is not required in the postal address for all countries, however. If you only want to show it
  # if it's required in the postal address, you can make it conditional based on
  # state_included_in_postal_address?.
  def self.states_for_country(country)
    return [] unless country
    raise ArgumentError.new('expected a Carmen::Country') unless country.is_a? Carmen::Country
    Carmen::RegionCollection.new(
      if country.name == 'Kenya'
        # https://github.com/jim/carmen/issues/227
        # https://en.wikipedia.org/wiki/Provinces_of_Kenya
        # Kenya's provinces were replaced by a system of counties in 2013.
        # https://en.wikipedia.org/wiki/ISO_3166-2:KE confirms that they are "former" provinces.
        # At the time of this writing, however, it doesn't look like Carmen has been updated to
        # include the 47 counties listed under https://en.wikipedia.org/wiki/ISO_3166-2:KE.
        country.subregions.typed('county')
      elsif country.name == 'France'
        # https://github.com/jim/carmen/issues/228
        # https://en.wikipedia.org/wiki/Regions_of_France
        # In 2016 what had been 27 regions was reduced to 18.
        # France is divided into 18 administrative regions, including 13 metropolitan regions and 5 overseas regions.
        # https://en.wikipedia.org/wiki/ISO_3166-2:FR
        []
      else # Needed for New Zealand, Philippines, Indonesia, and possibly others
        country.subregions.map {|_| _.subregions.any? ? _.subregions : _ }.flatten
      end
    )
  end
  def states_for_country
    self.class.states_for_country(carmen_country)
  end
  alias_method :state_options, :states_for_country

  def country_with_states?
    states_for_country.any?
  end

  # Is the state/province required in a postal address?
  # If no, perhaps you want to collect it for other reasons (like seeing which people/things are in
  # the same region). Or for countries where it *may* be included in a postal address but is not
  # required to be included.
  def state_required_in_postal_address?
    [
      'Australia',
      'Brazil',
      'Canada',
      'Mexico',
      'United States',
      'Italy',
      'Venezuela',
    ].include? country_name
  end
  def state_possibly_included_in_postal_address?
    # https://ux.stackexchange.com/questions/64665/address-form-field-for-region
    # http://www.bitboost.com/ref/international-address-formats/denmark/
    # http://www.bitboost.com/ref/international-address-formats/poland/
    return true if state_required_in_postal_address?
    return false if [
      'Algeria',
      'Argentina',
      'Austria',
      'Denmark',
      'France',
      'Germany',
      'Indonesia',
      'Ireland',
      'Israel',
      'Netherlands',
      'New Zealand',
      'Poland',
      'Sweden',
      'United Kingdom',
    ].include? country_name
    # Default:
    country_with_states?
  end

  # It's not called a "State" in all countries.
  # In some countries, it could technically be multiple different types of regions:
  # - In United States, it could be a state or an outlying region or a district or an APO
  # - In Canada, it could be a province or a territory.
  # This attempts to return the most common, expected name for this field.
  # See also: https://ux.stackexchange.com/questions/64665/address-form-field-for-region
  #
  # To see what it should be called in all countries known to Carmen:
  # Country.countries_with_states.map {|country| [country.name, Address.new(country_name: country.name).state_label] }.to_h
  # => {"Afghanistan"=>"Province",
  #     "Armenia"=>"Province",
  #     "Angola"=>"Province",
  #     "Argentina"=>"Province",
  #     "Austria"=>"State",
  #     "Australia"=>"State",
  #     ...
  def state_label
    # In UK, it looks like they (optionally) include the *county* in their addresses. They don't actually have "states" per se.
    # Reference: http://bitboost.com/ref/international-address-formats/united-kingdom/
    # Could also limit to Countries (England, Scotland, Wales) and Provinces (Northern Ireland).
    # Who knows. The UK's subregions are a mess.
    # If allowing the full list of subregions from https://en.wikipedia.org/wiki/ISO_3166-2:GB,
    # perhaps Region is a better, more inclusive term.
    if country_name.in? ['United Kingdom']
      'Region'
    elsif state_options.any?
      state_options[0].type.capitalize
    end
  end

  def state_name
    carmen_state ? carmen_state.name : state
  end

  #=================================================================================================

  def empty?
    [:address, :city, :state, :postal_code, :country].all? {|_|
      !self[_].present?
    }
  end

  def started_filling_out?
    [:address, :city, :state, :postal_code, :country].any? {|_|
      self[_].present?
    }
  end

  #=================================================================================================
  # Formatting for humans

  # Lines of a postal address
  def lines
    [
      name,
      address.to_s.lines.to_a,
      city_line,
      country_name,
    ].flatten.reject(&:blank?)
  end

  # Used by #lines
  #
  # Instead of using `state` method (which is really state_code). That's fine for some countries
  # like US, Canada, Australia but not other countries (presumably).
  #
  # TODO: Put postal code and city in a different order, as that countries conventions dictate.
  # See http://bitboost.com/ref/international-address-formats/new-zealand/
  #
  def city_line
    [
      #[city, state].reject(&:blank?).join(', '),
      [city, state_for_postal_address].reject(&:blank?).join(', '),
      postal_code,
    ].reject(&:blank?).join(' ')
  end

  def city_state_code
    [city, state].reject(&:blank?).join(', ')
  end

  def city_state_name
    [city, state_name].reject(&:blank?).join(', ')
  end

  def city_state_country
    [city_state_name, country_name].join(', ')
  end

  def state_for_postal_address
    # Possibly others use a code? But seems safer to default to a name until confirmed that they use
    # a code.
    if country_name.in? ['United States', 'Canada', 'Australia']
      state_code
    elsif state_possibly_included_in_postal_address?
      state_name
    else
      ''
    end
  end

  #=================================================================================================
  # Misc. output

  def parts
    [
      name,
      address.to_s.lines.to_a,
      city,
      state_name,
      postal_code,
      country_name,
    ].flatten.reject(&:blank?)
  end

  def inspect
    inspect_with([:id, :name, :address, :city, :state, :postal_code, :country], ['{', '}'])
  end

  #-------------------------------------------------------------------------------------------------
end
