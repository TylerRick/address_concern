class Employee < ActiveRecord::Base
  belongs_to_address :home_address, foreign_key: :physical_address_id, inverse: {name: :employee_home, foreign_key: :physical_address_id}
  belongs_to_address :work_address, dependent: :destroy,               inverse: {name: :employee_work}
end
