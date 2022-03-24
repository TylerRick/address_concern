module AddressConcern::Address
  module Base
    extend ActiveSupport::Concern

    module ClassMethods
      def acts_as_address(**options)
        @acts_as_address_config = config = { 
          state: {
            #code_attribute: :state,
            code_attribute: column_for_attribute(:state_code).presence&.name ||
                           (column_for_attribute(:state).presence&.name unless options.dig('state', 'name_attribute').to_s == 'state'),

            name_attribute: column_for_attribute(:state_name).presence&.name ||
                           (column_for_attribute(:state).presence&.name unless options.dig('state', 'code_attribute').to_s == 'state'),
            #name_attribute: :state_name,
          },
          country: {
            # By default, coded (same as country_alpha2) will be used
            carmen_code: :coded, # :country_alpha2, :country_alpha3

            #code_attribute: :country,
            code_attribute: column_for_attribute(:country_code).presence&.name ||
                           (column_for_attribute(:country).presence&.name unless options.dig('country', 'name_attribute').to_s == 'country'),

            name_attribute: column_for_attribute(:country_name).presence&.name ||
                           (column_for_attribute(:country).presence&.name unless options.dig('country', 'code_attribute').to_s == 'country'),
            #name_attribute: :country_name,
          },
        }.deep_merge(options)

        [:state, :country].each do |group|
          if config[group][:code_attribute] == config[group][:name_attribute]
            config[group].delete(:code_attribute)
          end
        end

        include ::AddressConcern::Address
      end

      def country_config
        config = @acts_as_address_config[:country] || {}
      end

      def state_config
        config = @acts_as_address_config[:state] || {}
      end

      def belongs_to_addressable(**options)
        belongs_to :addressable, polymorphic: true, touch: true, optional: true, **options
      end
    end
  end

  extend ActiveSupport::Concern
  included do
    #═════════════════════════════════════════════════════════════════════════════════════════════════
    #validates_presence_of :name
    #validates_presence_of :address
    #validates_presence_of :state, :if => :state_required?
    #validates_presence_of :country
    #validates_format_of :phone, :with => /^[0-9\-\+ ]*$/
    #validates_format_of :email, :with => /^[^@]*@.*\.[^\.]*$/, :message => 'is invalid. Please enter an address in the format of you@company.com'
    #validates_presence_of :phone, :message => ' is required.'

    #═════════════════════════════════════════════════════════════════════════════════════════════════
    normalize_attributes :city, :state, :postal_code, :country
    normalize_attribute  :address, :with => [:cleanlines, :strip]

    #═════════════════════════════════════════════════════════════════════════════════════════════════
    # Country & State

    # Some of these methods look up by either name or code

    def self.find_carmen_country(name)
      return name if name.is_a? Carmen::Country

      (
        find_carmen_country_by_name(name) ||
        find_carmen_country_by_code(name)
      )
    end
    def self.find_carmen_country!(name)
      find_carmen_country(name) or
        raise "country #{name} not found"
    end

    def self.find_carmen_country_by_name(name)
      name = recognize_country_name_alias(name)
      Carmen::Country.named(name)
    end

    def self.find_carmen_country_by_code(code)
      Carmen::Country.send(carmen_country_code, code)
    end

    def self.carmen_code_for(country)
      country.send(carmen_country_code)
    end

    #─────────────────────────────────────────────────────────────────────────────────────────────────

    def recognize_country_name_alias(name)
      name = case name
      when 'USA'
        'United States'
      when 'The Democratic Republic of the Congo', 'Democratic Republic of the Congo'
        'Congo, the Democratic Republic of the'
      when 'Republic of Macedonia', 'Macedonia, Republic of', 'Macedonia'
        'Macedonia, Republic of'
      else
        name
      end
    end

    #─────────────────────────────────────────────────────────────────────────────────────────────────

    def self.find_carmen_state(country_name, name)
      return name if name.is_a? Carmen::Region

      country = find_carmen_country!(country_name)
      states = states_for_country(country)
      (
        states.named(name) ||
        states.coded(name)
      )
    end
    def self.find_carmen_state!(country_name, name)
      find_carmen_state(country_name, name) or
        raise "state #{name} not found for country #{country_name}"
    end

    #─────────────────────────────────────────────────────────────────────────────────────────────────

    scope :in_country, ->(country_name) {
      country = find_carmen_country!(country_name)
      where(addresses: { country_code: country&.code })
    }
    scope :in_state, ->(country_name, name) {
      country = find_carmen_country!(country_name)
      state   = find_carmen_state!(country_name, name)
      where(addresses: { country_code: country&.code, state_code: state&.code })
    }

    #─────────────────────────────────────────────────────────────────────────────────────────────────

    def carmen_country
      # Carmen::Country.coded(country_code)
      Carmen::Country.send(config.carmen_country_code, country_code)
    end

    def carmen_state
      if (country = carmen_country)
        # country.subregions.coded(state_code)
        self.class.states_for_country(country).coded(state_code)
      end
    end

    #═════════════════════════════════════════════════════════════════════════════════════════════════
    # country attribute(s)

    def config
      self.class
    end

    def self.carmen_country_code
      country_config[:carmen_code]
    end

    def self.country_name_attribute
      country_config[:name_attribute]
    end

    def self.country_code_attribute
      country_config[:code_attribute]
    end

    #─────────────────────────────────────────────────────────────────────────────────────────────────
    # setters

    def clear_country
      write_attribute(config.country_name_attribute, nil) if config.country_name_attribute
      write_attribute(config.country_code_attribute, nil) if config.country_code_attribute
    end

    def set_country_from_carmen_country(country)
      write_attribute(config.country_name_attribute, country.name            ) if config.country_name_attribute
      write_attribute(config.country_code_attribute, carmen_code_for(country)) if config.country_code_attribute
    end

    #─────────────────────────────────────────────────────────────────────────────────────────────────
    # code=

    # def country_code=(code)
    define_method :"#{country_code_attribute}=" do |code|
      if code.blank?
        clear_country
      elsif (country = find_carmen_country_by_code(code))
        # Only set it if it's a recognized country code
        set_country_from_carmen_country(country)
      end
    end

    #─────────────────────────────────────────────────────────────────────────────────────────────────
    # name=

    # def country_name=(name)
    define_method :"#{country_name_attribute}=" do |name|
      if name.blank?
        clear_country
      else
        if (country = config.find_carmen_country_by_name(name))
          set_country_from_carmen_country(country)
        else
          clear_country
        end
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

    #════════════════════════════════════════════════════════════════════════════════════════════════════
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

    #════════════════════════════════════════════════════════════════════════════════════════════════════

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

    #════════════════════════════════════════════════════════════════════════════════════════════════════
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

    #════════════════════════════════════════════════════════════════════════════════════════════════════
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
end

ActiveRecord::Base.class_eval do
  include AddressConcern::Address::Base
end
