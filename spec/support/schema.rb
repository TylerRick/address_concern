ActiveRecord::Schema.define do
  create_table :users, :force => true do |t|
    t.string :name
  end
  create_table :companies, :force => true do |t|
    t.string :name
  end
end

