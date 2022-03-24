# frozen_string_literal: true

module AddressConcern
module AttributesSlice
  extend ActiveSupport::Concern

  # Returns a hash containing the attributes with the keys passed in, similar to
  # attributes.slice(*attr_names).
  #
  # This lets you use a list of attr_names as symbols to get a subset of attributes.
  # Because writing attributes.symbolize_keys.slice is too long.
  #
  # Unlike with attributes.slice, these "attributes" can be any instance method of the receiver;
  # they don't have to be present in the `attributes` hash itself. (The `attributes` hash only
  # includes columns in the associated table, not "virtual attributes" that are available only as
  # Ruby methods and not present as columns in the table. attributes.slice also doesn't let you
  # access the attributes via any attribute aliases you've added.)
  #
  # If you _don't_ want to include virtual attributes, pass include_virtual: false.
  #
  # Examples:
  #   attributes_slice
  #   => {}
  #
  #   attributes_slice(:name, :age, :confirmed?)
  #   => {:name => 'First Last', :age => 42, :confirmed? => true}
  #
  #   attributes_slice(:name, is_confirmed: :confirmed?)
  #   => {:name => 'First Last', :is_confirmed => true}
  #
  #   attributes_slice(:name, is_confirmed: -> { _1.confirmed? })
  #   => {:name => 'First Last', :is_confirmed => true}
  #
  def attributes_slice(*attr_names, include_virtual: true, **hash)
    hash.transform_values { |_proc|
      _proc.to_proc.call(self)
    }.reverse_merge(
      if include_virtual
        attr_names.each_with_object({}.with_indifferent_access) do |attr_name, hash|
          hash[attr_name] = send(attr_name)
        end
      else
        # When we only want "real" attributes
        attributes.symbolize_keys.slice(*keys.map(&:to_sym)).with_indifferent_access
      end
    )
  end
  alias_method :read_attributes, :attributes_slice

  def attributes_except(*keys)
    attributes.symbolize_keys.except(*keys.map(&:to_sym))
  end
end
end
