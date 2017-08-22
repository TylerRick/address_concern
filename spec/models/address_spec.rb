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

      #expect { expect {
      address.country = 'Fireland'
      #}.to change(address, :country_name).to(nil)
      #}.to change(address, :country_code).to(nil)
      address.country_name.should eq nil
      address.country_code.should eq nil
    end

    describe 'setting to a country that is part of another country (weird)' do; specify do
      address.country = 'Northern Ireland'
      address.country_code.should == 'GB'
      address.country_name.should           == 'Northern Ireland'
      address.country_name_from_code.should == 'United Kingdom'
    end; end

    describe 'country aliases:' do
      1.times do specify _='USA' do
        address.country = _
        address.country_name.should           == 'United States'
        address.country_name_from_code.should == 'United States'
      end; end

      1.times do specify _='Vietnam' do
        address.country = _
        address.country_name.should           == 'Vietnam'
        address.country_name_from_code.should == 'Vietnam'
      end; end

      1.times do specify _='Democratic Republic of Congo' do
        address.country = _
        address.country_name.should           == 'Democratic Republic of Congo'
        address.country_name_from_code.should == "Congo, The Democratic Republic of the"
      end; end

      ['Macedonia', 'Republic of Macedonia'].each do |_| specify _ do
        address.country = _
        address.country_name.should           == _
        address.country_name_from_code.should == 'Macedonia, Republic of'
      end; end
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

      #expect { expect {
      address.country = 'FL'
      #}.to change(address, :country_name).to(nil)
      #}.to change(address, :country_code).to(nil)
      address.country_name.should eq nil
      address.country_code.should eq nil
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
      [:name, :city, :state, :postal_code, :country].each do |attr_name|
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

  describe '#carmen_country' do
    it { Address.new(country: 'South Africa').carmen_country.should be_a Carmen::Country }
  end
  describe '#states_for_country' do
    it { Address.new(country: 'USA').         states_for_country.map(&:name).should include 'Ohio' }
    it { Address.new(country: 'South Africa').states_for_country.map(&:name).should include 'Mpumalanga' }
    # Not ["Northern Ireland", "Middlesex", "Wiltshire"]
    it { Address.new(country: 'United Kingdom').states_for_country.map(&:name).should eq [] }
  end
  describe '#carmen_state' do
    it { Address.new(country: 'USA',          state: 'OH!').carmen_state.should be_nil }
    it { Address.new(country: 'USA',          state: 'OH').carmen_state.should be_a Carmen::Region }
    it { Address.new(country: 'USA',          state: 'AA').carmen_state.should be_a Carmen::Region }
    it { Address.new(country: 'South Africa', state: 'MP').carmen_state.should be_a Carmen::Region }
  end

  describe 'associations' do
    # To do (or maybe not even necessary—seems to work with only the has_one side of the association):
    #describe 'when we have a polymorphic belongs_to :addressable in Address' do
    #belongs_to :addressable, :polymorphic => true

    describe 'has_one :address' do
      let(:company) { Company.create }

      it do
        company.address.should == nil
        address = company.build_address(address: '1')
        company.save!
        company.reload.address.should == address
      end

    end

    describe 'has_many :addresses' do
      let(:user) { User.create }

      it do
        user.addresses.should == []
        address_1 = user.addresses.build(address: '1')
        address_2 = user.addresses.build(address: '2')
        user.save!; user.reload
        user.addresses.should == [address_1, address_2]
      end

      specify 'should able to set and retrieve a specific address by type (shipping or billing)' do
        physical_address = user.build_physical_address(address: 'Physical')
        shipping_address = user.build_shipping_address(address: 'Shipping')
        billing_address  = user.build_billing_address( address: 'Billing')
        vacation_address = user.addresses.build(address: 'Vacation', :address_type => 'Vacation')
        user.save!; user.reload
        user.physical_address.should == physical_address
        user.shipping_address.should == shipping_address
        user.billing_address. should == billing_address
        user.addresses.to_set.should == [physical_address, shipping_address, billing_address, vacation_address].to_set
      end
    end
  end
end
