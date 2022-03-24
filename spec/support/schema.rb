ActiveRecord::Schema.define do
  # In order to avoid duplication, and to ensure that the template migration is valid, the schema for :addresses table can be found in lib/generators/address_concern/templates/migration.rb

  create_table :address_with_code_or_name_only do |t|
    t.text     :address
    t.string   :city
    t.string   :state
    t.string   :postal_code
    t.string   :country
    t.timestamps
  end

  create_table :address_with_separate_address_columns do |t|
    t.string   :address_1
    t.string   :address_2
    t.string   :address_3
    t.string   :city
    t.string   :state
    t.string   :postal_code
    t.string   :country
    t.timestamps
  end

  create_table :users, :force => true do |t|
    t.string :name
  end
  create_table :employees, :force => true do |t|
    t.string :name
    t.belongs_to :physical_address
    t.belongs_to :work_address
  end
  create_table :companies, :force => true do |t|
    t.string :name
  end
  create_table :children, :force => true do |t|
    t.string :name
    t.belongs_to :address
    t.belongs_to :secret_hideout
  end
end

