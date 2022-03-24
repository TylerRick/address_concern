class CreateAddresses < ActiveRecord::Migration[4.2]
  def self.up
    create_table :addresses do |t|
      t.references :addressable, :polymorphic => true
      t.string   :address_type   # to allow shipping/billing/etc. address

      t.text     :address
      t.string   :city
      t.string   :state_code
      t.string   :state
      t.string   :postal_code
      t.string   :country_code
      t.string   :country

      # You could add other columns, such as these, but they are arguably not technically part of an
      # address. In any case, they are outside the scope of this library.
      #t.string   :name
      #t.string   :email
      #t.string   :phone

      t.timestamps
    end

    change_table :addresses do |t|
      t.index  :addressable_id
      t.index  :addressable_type
      t.index  :address_type

      #t.index  :city
      t.index  :state_code
      t.index  :state
      #t.index  :postal_code
      t.index  :country_code
      t.index  :country
    end
  end

  def self.down
    drop_table :addresses
  end
end
