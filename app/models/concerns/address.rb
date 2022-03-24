require_relative '../../../lib/core_extensions/hash/reorder'
using Hash::Reorder

require_relative '../../../lib/core_extensions/string/cleanlines'
using String::Cleanlines

require_relative 'inspect_base'
require_relative 'attributes_slice'

module AddressConcern
module Address
  module Base
    extend ActiveSupport::Concern

    # These (Base) class methods are added to ActiveRecord::Base so that they will be available from _any_
    # model class. Unlike the main AddressConcern::Address methods which are only included _after_
    # you call acts_as_address on a model.
    module ClassMethods
      attr_reader :acts_as_address_config
      def acts_as_address(**options)
        # Have to use yield_self(&not_null) intead of presence because NullColumn.present? => true.
        not_null = ->(column) {
          column.type.nil? ? nil : column
        }
        options = options.deep_symbolize_keys
        default_config = {
          state: {
            #normalize: false,
            #validate: false,

            code_attribute: column_for_attribute(:state_code).yield_self(&not_null)&.name ||
                           (column_for_attribute(:state).yield_self(&not_null)&.name unless options.dig(:state, :name_attribute).to_s == 'state'),

            name_attribute: column_for_attribute(:state_name).yield_self(&not_null)&.name ||
                           (column_for_attribute(:state).yield_self(&not_null)&.name unless options.dig(:state, :code_attribute).to_s == 'state'),

            on_unknown: ->(value, name_or_code) { },
          },

          country: {
            #normalize: false,
            #validate: false,

            # By default, code (same as alpha_2_code) will be used
            carmen_code: :code, # or alpha_2_code, alpha_3_code, :numeric_code

            code_attribute: column_for_attribute(:country_code).yield_self(&not_null)&.name ||
                           (column_for_attribute(:country).yield_self(&not_null)&.name unless options.dig(:country, :name_attribute).to_s == 'country'),

            name_attribute: column_for_attribute(:country_name).yield_self(&not_null)&.name ||
                           (column_for_attribute(:country).yield_self(&not_null)&.name unless options.dig(:country, :code_attribute).to_s == 'country'),

            on_unknown: ->(value, name_or_code) { },
          },

          address: {
            #normalize: false,
            #validate: false,

            # Try to auto-detect address columns
            attributes: column_names.grep(/address$|^address_\d$/),
          }
        }
        @acts_as_address_config = config = {
          **default_config
        }.deep_merge(options)

        [:state, :country].each do |group|
          # Can't use the same column for code and name, so if it would be the same (by default or
          # otherwise), let it be used for name only instead.
          if config[group][:code_attribute] == config[group][:name_attribute]
            config[group].delete(:code_attribute)
          end
        end

        include ::AddressConcern::Address
      end

      def belongs_to_addressable(**options)
        belongs_to :addressable, polymorphic: true, touch: true, optional: true, **options
      end
    end
  end

  include InspectBase
  include AttributesSlice

  extend ActiveSupport::Concern
  included do
    #═══════════════════════════════════════════════════════════════════════════════════════════════
    # Config

    delegate *[
      :acts_as_address_config,
      :country_config,
      :state_config,
    ], to: 'self.class'

    class << self
      #─────────────────────────────────────────────────────────────────────────────────────────────
      def country_config
        @acts_as_address_config[:country] || {}
      end

      # usually :code
      def carmen_country_code
        country_config[:carmen_code]
      end

      # usually :coded
      def carmen_country_code_find_method
        :"#{carmen_country_code}d"
      end

      # 'country' or similar
      def country_name_attribute
        country_config[:name_attribute]&.to_sym
      end

      def country_code_attribute
        country_config[:code_attribute]&.to_sym
      end

      #─────────────────────────────────────────────────────────────────────────────────────────────

      def state_config
        @acts_as_address_config[:state] || {}
      end

      def carmen_state_code
        state_config[:carmen_code]
      end

      def state_name_attribute
        state_config[:name_attribute]&.to_sym
      end

      def state_code_attribute
        state_config[:code_attribute]&.to_sym
      end

      #─────────────────────────────────────────────────────────────────────────────────────────────

      def address_attr_config
        @acts_as_address_config[:address] || {}
      end

      # TODO: rename to something different than the same name as #address_attributes, like
      # street_address_attr_names
      def address_attributes
        Array(address_attr_config[:attributes]).map(&:to_sym)
      end

      # Address line 1
      def address_attribute
        address_attributes[0]
      end

      def multi_line_address?
        address_attributes.size == 1 && (
          column = column_for_attribute(address_attribute)
          column.type == :text
        )
      end

      #─────────────────────────────────────────────────────────────────────────────────────────────

      # AKA configured_address_attributes
      def address_attr_names
        [
          *address_attributes,
          :city,
          state_name_attribute,
          state_code_attribute,
          :postal_code,
          country_name_attribute,
          country_code_attribute,
        ].compact.uniq
      end
    end

    #═════════════════════════════════════════════════════════════════════════════════════════════════
    # Customizable validation (to add?)

    #validates_presence_of :address
    #validates_presence_of :state, if: :state_required?
    #validates_presence_of :country

    #═════════════════════════════════════════════════════════════════════════════════════════════════
    # Attributes

    def _assign_attributes(attributes)
      attributes = attributes.symbolize_keys
      attributes = reorder_language_attributes(attributes)
      super(attributes)
    end

    def self.country_aliases ; [:country_name, :country_code] ; end
    def self.state_aliases   ; [:state_name,   :state_code]   ; end

    # country needs to be assigned _before_ state for things to work as intended (can't look up
    # state in state= unless we know which country it is for)
    def reorder_language_attributes(attributes)
      attributes.reorder(self.class.country_name_attribute,  self.class.country_code_attribute, *self.class.country_aliases,
                         self.class.  state_name_attribute,  self.class.  state_code_attribute, *self.class.state_aliases)
    end

    def address_attributes
      attributes_slice(
        *self.class.address_attr_names
      )
    end

    #═════════════════════════════════════════════════════════════════════════════════════════════════

    # TODO: automatically normalize if attribute_normalizer/normalizy gem is loaded? add a config option to opt out?
    #normalize_attributes :city, :state, :postal_code, :country
    #normalize_attribute  *address_attributes, with: [:cleanlines, :strip]

    #═════════════════════════════════════════════════════════════════════════════════════════════════
    # Country & State (Carmen + custom)

    # Some of these methods look up by either name or code

    #─────────────────────────────────────────────────────────────────────────────────────────────────
    # find country

    # Finds by name, falling back to finding by code.
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
      # Carmen::Country.coded(code)
      Carmen::Country.send(carmen_country_code_find_method, code)
    end

    #─────────────────────────────────────────────────────────────────────────────────────────────────
    # find state

    # Finds by name, falling back to finding by code.
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

    def self.find_carmen_state_by_name(country_name, name)
      country = find_carmen_country!(country_name)
      states = states_for_country(country)
      states.named(name)
    end

    def self.find_carmen_state_by_code(country_name, code)
      country = find_carmen_country!(country_name)
      states = states_for_country(country)
      states.coded(code)
    end

    #─────────────────────────────────────────────────────────────────────────────────────────────────
    # country

    # Calls country.code
    _ = def self.carmen_country_code_for(country)
      country.send(carmen_country_code)
    end
    delegate _, to: 'self.class'

    # If you are storing both a country_name and country_code...
    # This _should_ be the same as the value stored in the country attribute, but allows you to
    # look it up just to make sure they match (or to update country field to match this).
    def country_name_from_code
      if (country = self.class.find_carmen_country_by_code(country_code))
        country.name
      end
    end
    def country_code_from_name
      if (country = self.class.find_carmen_country_by_name(country_name))
        self.class.carmen_country_code_for(country)
      end
    end

    #─────────────────────────────────────────────────────────────────────────────────────────────────
    # state

    def state_name_from_code
      if carmen_country && (state = self.class.find_carmen_state_by_code(carmen_country, state_code))
        state.name
      end
    end
    def state_code_from_name
      if carmen_country && (state = self.class.find_carmen_state_by_name(carmen_country, state_name))
        state.code
      end
    end

    #─────────────────────────────────────────────────────────────────────────────────────────────────
    # country

    def self.recognize_country_name_alias(name)
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
      self.class.find_carmen_country_by_code(country_code)
    end

    def carmen_state
      if (country = carmen_country)
        # country.subregions.coded(state_code)
        self.class.states_for_country(country).coded(state_code)
      end
    end

    #═════════════════════════════════════════════════════════════════════════════════════════════════
    # country attribute(s)

    #─────────────────────────────────────────────────────────────────────────────────────────────────
    # setters


    def clear_country
      write_attribute(self.class.country_name_attribute, nil) if self.class.country_name_attribute
      write_attribute(self.class.country_code_attribute, nil) if self.class.country_code_attribute
    end

    def set_country_from_carmen_country(country)
      write_attribute(self.class.country_name_attribute, country.name                    ) if self.class.country_name_attribute
      write_attribute(self.class.country_code_attribute, carmen_country_code_for(country)) if self.class.country_code_attribute
    end

    #─────────────────────────────────────────────────────────────────────────────────────────────────
    # code=

    # def country_code=(code)
    define_method :"#{country_code_attribute || 'country_code'}=" do |value|
      if value.blank?
        clear_country
      else
        if (country = self.class.find_carmen_country_by_code(value))
          set_country_from_carmen_country(country)
        else
          country_config[:on_unknown].(value, :code)
          write_attribute(self.class.country_code_attribute, value) if self.class.country_code_attribute
        end
      end
    end

    # Attribute alias
    if country_code_attribute
      unless :country_code == country_code_attribute
        alias_attribute :country_code, :"#{country_code_attribute}"
        #alias_method :country_code=, :"#{country_code_attribute}="
      end
    else
      alias_method :country_code, :country_code_from_name
    end

    #─────────────────────────────────────────────────────────────────────────────────────────────────
    # name=

    # def country_name=(name)
    define_method :"#{country_name_attribute || 'country_name'}=" do |value|
      if value.blank?
        clear_country
      else
        if (country = self.class.find_carmen_country_by_name(value))
          set_country_from_carmen_country(country)
        else
          country_config[:on_unknown].(value, :name)
          write_attribute(self.class.country_name_attribute, value) if self.class.country_name_attribute
        end
      end
    end

    # Attribute alias
    if country_name_attribute
      unless :country_name == country_name_attribute
        alias_attribute :country_name, country_name_attribute
        #alias_method :country_name=, :"#{country_name_attribute}="
      end
    else
      alias_method :country_name, :country_name_from_code
    end

    #════════════════════════════════════════════════════════════════════════════════════════════════════
    # state attribute(s)
    # (This is nearly identical to country section above with s/country/state/)

    #─────────────────────────────────────────────────────────────────────────────────────────────────
    # setters


    def clear_state
      write_attribute(self.class.state_name_attribute, nil) if self.class.state_name_attribute
      write_attribute(self.class.state_code_attribute, nil) if self.class.state_code_attribute
    end

    def set_state_from_carmen_state(state)
      write_attribute(self.class.state_name_attribute, state.name) if self.class.state_name_attribute
      write_attribute(self.class.state_code_attribute, state.code) if self.class.state_code_attribute
    end

    #─────────────────────────────────────────────────────────────────────────────────────────────────
    # code=

    # def state_code=(code)
    define_method :"#{state_code_attribute || 'state_code'}=" do |value|
      if value.blank?
        clear_state
      else
        if carmen_country && (state = self.class.find_carmen_state_by_code(carmen_country, value))
          set_state_from_carmen_state(state)
        else
          #puts carmen_country ? "unknown state code '#{value}'" : "can't find state without country"
          state_config[:on_unknown].(value, :code)
          write_attribute(self.class.state_code_attribute, value) if self.class.state_code_attribute
        end
      end
    end

    # Attribute alias
    if state_code_attribute
      unless :state_code == state_code_attribute
        alias_attribute :state_code, :"#{state_code_attribute}"
        #alias_method :state_code=, :"#{state_code_attribute}="
      end
    else
      alias_method :state_code, :state_code_from_name
    end

    # alias_method :province, :state

    #─────────────────────────────────────────────────────────────────────────────────────────────────
    # name=

    # def state_name=(name)
    # Uses find_carmen_state so if your column was named 'state', you could actually do state = name
    # or code.
    define_method :"#{state_name_attribute || 'state_name'}=" do |value|
      if value.blank?
        clear_state
      else
        if carmen_country && (state = self.class.find_carmen_state(carmen_country, value))
          set_state_from_carmen_state(state)
        else
          #puts carmen_country ? "unknown state name '#{name}'" : "can't find state without country"
          state_config[:on_unknown].(value, :name)
          write_attribute(self.class.state_name_attribute, value) if self.class.state_name_attribute
        end
      end
    end

    # Attribute alias
    if state_name_attribute
      unless :state_name == state_name_attribute
        alias_attribute :state_name, state_name_attribute
        #alias_method :state_name=, :"#{state_name_attribute}="
      end
    else
      alias_method :state_name, :state_name_from_code
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
      country = find_carmen_country!(country)

      has_states_at_level_1 = country.subregions.any? { |region|
        region.type == 'state' ||
        region.type == 'province' ||
        region.type == 'metropolitan region'
      }
      has_states_at_level_1 = false if country.name == 'United Kingdom'

      if country.name == 'Kenya'
        # https://github.com/jim/carmen/issues/227
        # https://en.wikipedia.org/wiki/Provinces_of_Kenya
        # Kenya's provinces were replaced by a system of counties in 2013.
        # https://en.wikipedia.org/wiki/ISO_3166-2:KE confirms that they are "former" provinces.
        # At the time of this writing, however, it doesn't look like Carmen has been updated to
        # include the 47 counties listed under https://en.wikipedia.org/wiki/ISO_3166-2:KE.
        country.subregions.typed('county')
      #elsif country.name == 'France'
      #  # https://github.com/jim/carmen/issues/228
      #  # https://en.wikipedia.org/wiki/Regions_of_France
      #  # In 2016 what had been 27 regions was reduced to 18.
      #  # France is divided into 18 administrative regions, including 13 metropolitan regions and 5 overseas regions.
      #  # https://en.wikipedia.org/wiki/ISO_3166-2:FR
      #  []
      elsif has_states_at_level_1
        country.subregions
      else
        # Going below level-1 subregions is needed for Philippines, Indonesia, and possibly others
        Carmen::RegionCollection.new(
          country.subregions.
            map { |_| _.subregions.any? ? _.subregions : _ }.
            flatten
        )
      end
    end
    def states_for_country
      self.class.states_for_country(carmen_country)
    end
    alias_method :state_options, :states_for_country

    def country_with_states?
      states_for_country.any?
    end

    #───────────────────────────────────────────────────────────────────────────────────────────────

    # Used for checking/testing states_for_country.
    # Example:
    #   Address.compare_subregions_and_states_for_country('France');
    def self.compare_subregions_and_states_for_country(country)
      country = find_carmen_country!(country)
      states_for_country = states_for_country(country)
      if country.subregions == states_for_country
        puts '(Same:)'
        pp country.subregions
      else
        puts %(country.subregions (#{country.subregions.size}):\n#{country.subregions.pretty_inspect})
        puts
        puts %(states_for_country(country) (#{states_for_country.size}):\n#{states_for_country})
        states_for_country
      end
    end

    #───────────────────────────────────────────────────────────────────────────────────────────────

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

    #════════════════════════════════════════════════════════════════════════════════════════════════════

    def empty?
      address_attributes.all? do |key, value|
        value.blank?
      end
    end

    def present?
      address_attributes.any? do |key, value|
        value.present?
      end
    end

    #════════════════════════════════════════════════════════════════════════════════════════════════════
    # Street address / Address lines

    # Attribute alias for street address line 1
    #if address_attribute
    #  unless :address == address_attribute
    #    alias_attribute :address, :"#{address_attribute}"
    #  end
    #end

    def address_lines
      if self.class.multi_line_address?
        address.to_s.cleanlines.to_a
      else
        self.class.address_attributes.map do |attr_name|
          send attr_name
        end
      end
    end

    #════════════════════════════════════════════════════════════════════════════════════════════════════
    # Formatting for humans

    # Lines of a postal address
    def lines
      [
        #name,
        *address_lines,
        city_line,
        country_name,
      ].reject(&:blank?)
    end

    # Used by #lines
    #
    # Instead of using `state` method (which is really state_code). That's fine for some countries
    # like US, Canada, Australia but not other countries (presumably).
    #
    # TODO: Put postal code and city in a different order, as that country's conventions dictate.
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
      [city, state_code].reject(&:blank?).join(', ')
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

    # TODO: remove?
    def parts
      [
        #name,
        *address_lines,
        city,
        state_name,
        postal_code,
        country_name,
      ].reject(&:blank?)
    end

#    def inspect
#      inspect_base(
#        :id,
#        #:name,
#        :address,
#        # address_2 ...
#        :city,
#        :state,
#        :postal_code,
#        :country,
#      )
#    end

    def inspect
      inspect_base(
        :id,
        address_attributes
      )
    end

    #─────────────────────────────────────────────────────────────────────────────────────────────────
  end
end
end

ActiveRecord::Base.class_eval do
  include AddressConcern::Address::Base
end
