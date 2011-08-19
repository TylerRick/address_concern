class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
      t.references :addressable, :polymorphic => true
      t.string   :name
      t.text     :address
      t.string   :city
      t.string   :state
      t.string   :postal_code
      t.string   :country
      t.string   :country_alpha2
      t.string   :country_alpha3
      t.string   :email
      t.string   :phone
      t.timestamps
    end

    change_table :addresses do |t|
      t.index  :addressable_id
      t.index  :addressable_type
      t.index  :name
      t.index  :state
      t.index  :country
      t.index  :country_alpha2
      t.index  :country_alpha3
    end
  end

  def self.down
    drop_table :addresses
  end
end
