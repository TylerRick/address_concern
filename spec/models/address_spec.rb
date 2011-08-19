require 'spec_helper'

describe Address do
  describe 'setting country by name' do
    let(:address) { Address.new }
    specify 'setting to known country' do
      address.country = 'Iceland'
      address.country_name.should == 'Iceland'
      address.country_code.should == 'IS'
    end

    specify 'setting to unknown country' do
      # Set it to a known country first to show that it actually *clears* these fields if they were previously set
      address.country = 'Iceland'

      expect { expect {
      address.country = 'Fireland'
      }.to change(address, :country_name).to(nil)
      }.to change(address, :country_code).to(nil)
    end

    specify 'setting to a country that is part of another country (weird)' do
      address.country = 'Northern Ireland'
      address.country_name.should == 'Northern Ireland'
      address.country_code.should == 'GB'
      Carmen::country_name(address.country_code).should == 'United Kingdom'
    end
  end

  describe 'setting country by code' do
    let(:address) { Address.new }
    specify 'setting to known country' do
      address.country_code = 'IS'
      address.country_name.should == 'Iceland'
      address.country_code.should == 'IS'
    end

    specify 'setting to unknown country' do
      # Set it to a known country first to show that it actually *clears* these fields if they were previously set
      address.country_code = 'IS'

      expect { expect {
      address.country = 'FL'
      }.to change(address, :country_name).to(nil)
      }.to change(address, :country_code).to(nil)
    end

    specify 'setting to a country that is part of another country (weird)' do
      # Not currently possible using country_code=
    end
  end

  describe 'started_filling_out?' do
    [:address, :city, :state, :postal_code].each do |attr_name|
      it "should be true when #{attr_name} (and only #{attr_name}) is present" do
        Address.new(attr_name => 'something').should be_started_filling_out
      end
    end
    it "should be true when country (and only country) is present" do
      Address.new(:country => 'Latvia').should be_started_filling_out
    end
  end

  describe 'normalization' do
    describe 'address' do
      it { should normalize_attribute(:address).from("  Line 1  \n    Line 2    \n    ").to("Line 1\nLine 2")}
      [:name, :address, :city, :state, :postal_code, :country].each do |attr_name|
        it { should normalize_attribute(attr_name) }
      end
    end
  end

  describe 'parts and lines' do
    it do
      address = Address.new(
        address: '10 Some Road',
        city: 'Watford', state: 'Herts', postal_code: 'WD25 9JZ',
        country: 'England'
      )
      address.parts.should == [
        '10 Some Road',
        'Watford',
        'Herts',
        'WD25 9JZ',
        'England'
      ]
      address.lines.should == [
        '10 Some Road',
        'Watford, Herts WD25 9JZ',
        'England'
      ]
      address.city_line.should == 'Watford, Herts WD25 9JZ'
      address.city_state.should == 'Watford, Herts'
    end
  end

  describe 'same_as?' do
    it 'should be true when country is only present attribute and it matches' do
      Address.new(country: 'USA').should be_same_as(
      Address.new(country: 'USA'))
    end
    it 'should be true when country and state are only present attributes and they match' do
      Address.new(state: 'Washington', country: 'USA').should be_same_as(
      Address.new(state: 'Washington', country: 'USA'))
    end
    it "not should be true when address attribute doesn't match" do
      Address.new(address: '123 C St.', state: 'Washington', country: 'USA').should_not be_same_as(
      Address.new(address: '444 Z St.', state: 'Washington', country: 'USA'))
    end
  end
end
