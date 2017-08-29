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

      address.country = 'Northern Ireland'
      address.country_name.should eq nil
      address.country_code.should eq nil

      address.country = 'USA'
      address.country_name.should eq nil
      address.country_code.should eq nil
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

  describe 'country aliases:' do
    let(:address) { Address.new }
    ['The Democratic Republic of the Congo', 'Democratic Republic of the Congo'].each do |_| specify _ do
      address.country = _
      address.country_name.should           == 'Congo, The Democratic Republic of the'
      address.country_name_from_code.should == 'Congo, The Democratic Republic of the'
    end; end

    ['Macedonia', 'Republic of Macedonia'].each do |_| specify _ do
      address.country = _
      address.country_name.should           == 'Macedonia, Republic of'
      address.country_name_from_code.should == 'Macedonia, Republic of'
    end; end
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
        city: 'Watford', state: 'HRT', postal_code: 'WD25 9JZ',
        country: 'United Kingdom'
      )
      address.parts.should == [
        '10 Some Road',
        'Watford',
        'Hertfordshire',
        'WD25 9JZ',
        'United Kingdom'
      ]
      address.lines.should == [
        '10 Some Road',
        'Watford WD25 9JZ',
        'United Kingdom'
      ]
      address.city_line.should == 'Watford WD25 9JZ'
      address.city_state_name.should == 'Watford, Hertfordshire'
    end
  end

  describe '#city_state/#city_state_country' do
    context "when address doesn't have a state" do
      let(:user) { User.create }
      subject { user.build_physical_address(address: '123', city: 'Stockholm', country_name: 'Sweden') }
      it { subject.city_state_code.should    == 'Stockholm' }
      it { subject.city_state_name.should    == 'Stockholm' }
      it { subject.city_state_country.should == 'Stockholm, Sweden' }
    end
    context "when address has a state abbrevitation in :state field" do
      let(:user) { User.create }
      subject { user.build_physical_address(address: '123', city: 'Nelspruit', state: 'MP', country_name: 'South Africa') }
      it { subject.city_state_code.should    == 'Nelspruit, MP' }
      it { subject.city_state_name.should    == 'Nelspruit, Mpumalanga' }
      it { subject.city_state_country.should == 'Nelspruit, Mpumalanga, South Africa' }
    end
    context "when address has a state abbrevitation in :state field (Denmark)" do
      let(:user) { User.create }
      subject { user.build_physical_address(address: '123', city: 'Copenhagen', state: '84', country_name: 'Denmark') }
      it { subject.city_state_name.should    == 'Copenhagen, Hovedstaden' }
      it { subject.state_name.should         == 'Hovedstaden' }
    end

    # United States
    context "when address has a state name entered for :state instead of an abbreviation" do
      let(:user) { User.create }
      subject { user.build_physical_address(address: '123', city: 'Ocala', state: 'Florida', country_name: 'United States') }
      it { subject.city_state_code.should    == 'Ocala, Florida' }
      it { subject.city_state_name.should    == 'Ocala, Florida' }
      it { subject.city_state_country.should == 'Ocala, Florida, United States' }
    end
    context "when address has a state abbrevitation in :state field" do
      let(:user) { User.create }
      subject { user.build_physical_address(address: '123', city: 'Ocala', state: 'FL', country_name: 'United States') }
      it { subject.city_state_code.should    == 'Ocala, FL' }
      it { subject.city_state_name.should    == 'Ocala, Florida' }
      it { subject.city_state_country.should == 'Ocala, Florida, United States' }
    end
    context "when address has a state name entered for :state instead of an abbreviation, but state is for different country" do
      let(:user) { User.create }
      subject { user.build_physical_address(address: '123', city: 'Ocala', state: 'FL', country_name: 'Denmark') }
      it { subject.city_state_code.should    == 'Ocala, FL' }
      it { subject.city_state_name.should    == 'Ocala, FL' }
      it { subject.city_state_country.should == 'Ocala, FL, Denmark' }
    end
  end

  describe 'same_as?' do
    it 'should be true when country is only present attribute and it matches' do
      Address.new(country: 'United States').should be_same_as(
      Address.new(country: 'United States'))
    end
    it 'should be true when country and state are only present attributes and they match' do
      Address.new(state: 'Washington', country: 'United States').should be_same_as(
      Address.new(state: 'Washington', country: 'United States'))
    end
    it "not should be true when address attribute doesn't match" do
      Address.new(address: '123 C St.', state: 'Washington', country: 'United States').should_not be_same_as(
      Address.new(address: '444 Z St.', state: 'Washington', country: 'United States'))
    end
  end

  describe '#carmen_country' do
    it { Address.new(country: 'South Africa').carmen_country.should be_a Carmen::Country }
  end
  describe '#carmen_state' do
    it { Address.new(country: 'United States', state: 'OH!').carmen_state.should be_nil }
    it { Address.new(country: 'United States', state: 'OH').carmen_state.should be_a Carmen::Region }
    it { Address.new(country: 'United States', state: 'AA').carmen_state.should be_a Carmen::Region }
    it { Address.new(country: 'South Africa',  state: 'MP').carmen_state.should be_a Carmen::Region }
  end

  describe '#states_for_country, etc.' do
    it { Address.new(country: 'United States').states_for_country.map(&:code).should include 'AA' }
    it { Address.new(country: 'United States').states_for_country.map(&:name).should include 'Ohio' }
    it { Address.new(country: 'United States').states_for_country.map(&:name).should include 'District of Columbia' }
    it { Address.new(country: 'United States').states_for_country.map(&:name).should include 'Puerto Rico' }
    it { Address.new(country: 'South Africa').states_for_country.map(&:name).should include 'Mpumalanga' }
    it { Address.new(country: 'Kenya').states_for_country.typed('province').should be_empty }
    # At the time of this writing, it doesn't look like Carmen has been updated to
    # include the 47 counties listed under https://en.wikipedia.org/wiki/ISO_3166-2:KE.
    #it { Address.new(country: 'Kenya').states_for_country.map(&:name).should include 'Nyeri' }
    it { Address.new(country: 'Denmark').state_options.should be_many }
    it { Address.new(country: 'Denmark').state_options.map(&:name).should include 'Sjælland' }
    it { Address.new(country: 'Denmark').state_possibly_included_in_postal_address?.should eq false }
    # Auckland (AUK) is a subregion of the North Island (N) subregion
    it { Address.new(country: 'New Zealand').state_options.map(&:code).should include 'AUK' }
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
