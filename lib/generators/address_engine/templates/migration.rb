class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table "addresses", :force => true do |t|
      t.string   "email"
      t.string   "first_name"
      t.string   "last_name"
      t.text     "address"
      t.string   "city"
      t.string   "state_province_region"
      t.string   "zip_postal_code"
      t.string   "country"
      t.string   "phone"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "middle_name"
    end
  end

  def self.down
    drop_table :addresses
  end
end
