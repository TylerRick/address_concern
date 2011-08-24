class Address < ActiveRecord::Base
  belongs_to :addressable, :polymorphic => true
  
  #validates_presence_of :name
  #validates_presence_of :address
  #validates_presence_of :state, :if => :state_required?
  #validates_presence_of :country
  #validates_format_of :phone, :with => /^[0-9\-\+ ]*$/
  #validates_format_of :email, :with => /^[^@]*@.*\.[^\.]*$/, :message => 'is invalid. Please enter an address in the format of you@company.com'
  #validates_presence_of :phone, :message => ' is required.'
  
  #-------------------------------------------------------------------------------------------------
  normalize_attributes :name, :city, :state, :postal_code, :country
  normalize_attribute  :address, :with => [:cleanlines, :strip]

  #-------------------------------------------------------------------------------------------------
  # Country code

  def country_alpha2=(code)
    if code.blank?
      write_attribute(:country, nil)
      write_attribute(:country_alpha2, nil)
      write_attribute(:country_alpha3, nil)

    elsif (name = Carmen::country_name(code))
      # Only set it if it's a recognized country code
      write_attribute(:country, name)
      write_attribute(:country_alpha2, code)
    end
  end

  # Aliases
  def country_code
    country_alpha2
  end
  def country_code=(code)
    self.country_alpha2 = code
  end

  #-------------------------------------------------------------------------------------------------
  # Country name

  # TODO: we could detect if they're passing in a name or a code (if length <= 2) and delegate to country_code= if it's a code
  def country=(name)
    if name.blank?
      write_attribute(:country, nil)
      write_attribute(:country_alpha2, nil)
      write_attribute(:country_alpha3, nil)
    else
      name = case name
      when 'USA'
        'United States'
      when 'Vietnam'
        'Viet Nam'
      when 'Democratic Republic of the Congo', 'Democratic Republic of Congo'
        name_for_code = "Congo, the Democratic Republic of the"; name
      when 'Republic of Macedonia', 'Macedonia'
        name_for_code = "Macedonia, the Former Yugoslav Republic of"; name
      when 'England', 'Scotland', 'Wales', 'Northern Ireland'
        name_for_code = 'United Kingdom'; name
      else
        name
      end
      name_for_code ||= name

      if (code = Carmen::country_code(name_for_code))
        write_attribute(:country, name)
        write_attribute(:country_alpha2, code)
      else
        write_attribute(:country, nil)
        write_attribute(:country_alpha2, nil)
        write_attribute(:country_alpha3, nil)
      end
    end
  end

  # Sometimes this will be different from the value stored in the country attribute
  def country_name_from_code
    Carmen::country_name(country_code)
  end

  # Aliases
  def country_name
    country
  end
  def country_name=(name)
    self.country = name
  end

  #-------------------------------------------------------------------------------------------------
  
  def started_filling_out?
    [:address, :city, :state, :postal_code, :country].any? {|_|
      self[_].present?
    }
  end

  #-------------------------------------------------------------------------------------------------
  
  # TODO: remove? when is this useful?
  def parts
    [
      name,
      address.to_s.lines.to_a,
      city,
      state,
      postal_code,
      country_name,
    ].flatten.reject(&:blank?)
  end
  
  def lines
    [
      name,
      address.to_s.lines.to_a,
      city_line,
      country_name,
    ].flatten.reject(&:blank?)
  end

  # TODO: add country-specific address formatting
  def city_line
    [
      [city, state].reject(&:blank?).join(', '),
      postal_code,
    ].reject(&:blank?).join(' ')
  end

  def city_state
    [city, state].reject(&:blank?).join(', ')
  end

  #-------------------------------------------------------------------------------------------------

  def inspect
    inspect_with([:id, :name, :address, :city, :state, :postal_code, :country], ['{', '}'])
  end
  
  #-------------------------------------------------------------------------------------------------
end
