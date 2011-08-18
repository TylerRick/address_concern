class Address < ActiveRecord::Base
  belongs_to :addressable, :polymorphic => true
  
  #validates_presence_of :name
  #validates_presence_of :address
  #validates_presence_of :country
  #validates_format_of :phone, :with => /^[0-9\-\+ ]*$/
  #validates_format_of :email, :with => /^[^@]*@.*\.[^\.]*$/, :message => 'is invalid. Please enter an address in the format of you@company.com'
  #validates_presence_of :phone, :message => ' is required.'
  
  def country_code
    country #_code
  end
  def country_code=(code)
    self.country = code #_code
  end
  def country_name
    return if country.blank?
    Carmen::country_name(country)
    #Carmen::country_name(country_code)
  end
  def country_name=(name)
    if name.blank?
      self.country_code = nil
    else
      self.country_code = Carmen::country_code(name)
    end
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
      out << province if province.present?
      out << postal_code if postal_code.present?
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
      last_line << province if province.present?
      last_line << postal_code if postal_code.present?

      out << last_line.join(', ')
      out << country_name if country.present?
    end
  end
  
end
