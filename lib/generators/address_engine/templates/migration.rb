class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table "addresses" do |t|
      t.references :addressable, :polymorphic => true
      t.string   "name"
      t.text     "address"
      t.string   "city"
      t.string   "province"
      t.string   "postal_code"
      t.string   "country"
      t.string   "email"
      t.string   "phone"
      t.timestamps
    end
  end

  def self.down
    drop_table :addresses
  end
end
