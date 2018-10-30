ActiveRecord::Schema.define do
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

