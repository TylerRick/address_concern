# Comparable to the ActsAsAddressable concern of effective_addresses.
module AddressConcern::AddressAssociations
  extend ActiveSupport::Concern
  module ClassMethods
    # Creates a belongs_to +address+ association, named "address" by default but a different name may be
    # provided. In the Address model, creates an inverse association unless you pass +inverse: false+.
    #
    # You can pass options to the belongs_to, like this:
    #   belongs_to_address :work_address, dependent: :destroy
    #
    # You can also pass options to the inverse has_one assocation in the Address model, via the
    # +inverse+ option:
    #   belongs_to_address :home_address, inverse: {foreign_key: :physical_address_id}
    #
    def belongs_to_address(name = :address, inverse: nil, **options)
      options.reverse_merge!({
        class_name: 'Address'
      })
      raise "association :#{name} already exists on #{self}" if reflect_on_association(name)
      belongs_to name, **options
      #puts %(reflect_on_association(#{name})=#{reflect_on_association(name).inspect})

      unless inverse == false
        inverse ||= {}
        inverse.reverse_merge!({
          name:        self.name.underscore.to_sym,
          inverse_of:  name,
          class_name:  self.name,
          foreign_key: "#{name}_id",
        })
        name       = inverse.delete(:name)
        inverse_of = inverse.delete(:inverse_of)
        Address.class_eval do
          raise "association :#{name} already exists on #{self}" if reflect_on_association(name)
          has_one name, inverse_of: inverse_of, **inverse
          #puts %(reflect_on_association(#{name})=#{reflect_on_association(name).inspect})
        end
      end
    end

    # Creates a has_one +address+ association, representing the one and only address associated with the current record
    #
    # TODO: Let individual address names/types be defined, like has_address :billing. For now, have to use
    # has_addresses and define them all at once.
    #
    def has_address
      has_one :address, as: :addressable
      create_addressable_association_on_address_if_needed
    end

    # Creates a has_many +addresses+ association, representing all addresses associated with the current record
    #
    # Comparable to acts_as_addressable from effective_addresses.
    #
    def has_addresses(options = {})
      has_many :addresses, as: :addressable
      (options[:types] || ()).each do |type|
        has_one :"#{type}_address", -> { where({address_type: type}) }, class_name: 'Address', as: :addressable
      end
      create_addressable_association_on_address_if_needed
    end

    def create_addressable_association_on_address_if_needed(**options)
      Address.class_eval do
        return if reflect_on_association(:addressable)
      end
      Address.belongs_to_addressable(**options)
    end
  end
end

ActiveRecord::Base.class_eval do
  include AddressConcern::AddressAssociations
end
