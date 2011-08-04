class Address < ActiveRecord::Base
  belongs_to :addressable, :polymorphic => true
  
  #validates_presence_of :name
  #validates_presence_of :address
  #validates_presence_of :country
  #validates_format_of :phone, :with => /^[0-9\-\+ ]*$/
  #validates_format_of :email, :with => /^[^@]*@.*\.[^\.]*$/, :message => 'is invalid. Please enter an address in the format of you@company.com'
  #validates_presence_of :phone, :message => ' is required.'
  
  def country_name
    Carmen::country_name(country)
  end
  
  def filled_in?
    address? && country?
  end
  
  def parts
    [].tap do |out|
      out << name
      if address.present?
        address.split("\n").each do |line|
          out << line
        end
      end
      out << city if city.present?
      out << state_province_region if state_province_region.present?
      out << zip_postal_code if zip_postal_code.present?
      out << country_name if country.present?
    end
  end
  
  def readable_parts
    [].tap do |out|
      out << name

      if address.present?
        address.split("\n").each do |line|
          out << line
        end
      end
      
      last_line = []
      last_line << city if city.present?
      last_line << state_province_region if state_province_region.present?
      last_line << zip_postal_code if zip_postal_code.present?

      out << last_line.join(', ')
      out << country_name if country.present?
    end
  end
  
end
