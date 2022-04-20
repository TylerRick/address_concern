require 'spec_helper'

describe Address do
  def klass
    described_class
  end

  describe AddressWithNameOnly do
    it do
      expect(klass.state_name_attribute).to eq 'state'
      expect(klass.state_code_attribute).to eq nil
      expect(klass.country_name_attribute).to eq 'country'
      expect(klass.country_code_attribute).to eq nil
    end
  end

  describe AddressWithCodeOnly do
    it do
      address = klass.new(country_code: 'AE')
      expect(address.country_code).to eq 'AE'
    end
  end

  #═════════════════════════════════════════════════════════════════════════════════════════════════

  describe 'setting country by name' do
    let(:address) { Address.new }
    specify 'setting to known country' do
      address.country = 'Iceland'
      expect(address.country_name).to eq('Iceland')
      expect(address.country_code).to eq('IS')
    end

    context "setting to name instead of code" do
      subject { Address.new(country_name: 'US') }
      # Unlike state_name=, country_name does not use find_carmen_country. Usually with country
      # you'll know very well ahead of time whether you're dealing with names or codes. Less likely
      # with states.
      it { expect(subject.country_name).to eq(nil) }
    end

    specify 'setting to unknown country' do
      # Set it to a known country first to show that it actually *clears* these fields if they were previously set
      address.country = 'Iceland'

      #expect { expect {
      address.country = 'Fireland'
      #}.to change(address, :country_name).to(nil)
      #}.to change(address, :country_code).to(nil)
      expect(address.country_name).to eq nil
      expect(address.country_code).to eq nil

      address.country = 'Northern Ireland'
      expect(address.country_name).to eq nil
      expect(address.country_code).to eq nil

      address.country = 'Estados Unidos'
      expect(address.country_name).to eq nil
      expect(address.country_code).to eq nil
    end
  end

  describe 'setting country by code' do
    let(:address) { Address.new }
    specify 'setting to known country' do
      address.country_code = 'IS'
      expect(address.country_name).to eq('Iceland')
      expect(address.country_code).to eq('IS')
    end

    specify 'setting to unknown country' do
      # Set it to a known country first to show that it actually *clears* these fields if they were previously set
      address.country_code = 'IS'

      #expect { expect {
      address.country = 'FL'
      #}.to change(address, :country_name).to(nil)
      #}.to change(address, :country_code).to(nil)
      expect(address.country_name).to eq nil
      expect(address.country_code).to eq nil
    end
  end

  describe 'country aliases:' do
    let(:address) { Address.new }
    ['The Democratic Republic of the Congo', 'Democratic Republic of the Congo'].each do |_| specify _ do
      address.country = _
      expect(address.country_name).to           eq('Congo, The Democratic Republic of the')
      expect(address.country_name_from_code).to eq('Congo, The Democratic Republic of the')
    end; end
    it do
      address.country = 'USA'
      expect(address.country_name).to eq('United States')
    end
  end

  #═════════════════════════════════════════════════════════════════════════════════════════════════

  describe 'setting state by name' do
    context "simple" do
      subject { Address.new(state: 'FL', country_name: 'United States') }
      it { expect(subject.state_code).to eq('FL') }
    end

    context "setting to name instead of code" do
      subject { Address.new(state: 'Florida', country_name: 'United States') }
      # Uses find_carmen_state, which finds by name, falling back to finding by code.
      it { expect(subject.state_code).to eq('FL') }
    end
  end

  #═════════════════════════════════════════════════════════════════════════════════════════════════

  describe 'started_filling_out?' do
    let(:address) { Address.new }
    [:address, :city, :state, :postal_code].each do |attr_name|
      it "should be true when #{attr_name} (and only #{attr_name}) is present" do
        address.write_attribute attr_name, 'something'
        expect(address).to be_started_filling_out
      end
    end
    it "should be true when country (and only country) is present" do
      expect(Address.new(:country => 'Latvia')).to be_started_filling_out
    end
  end

  describe 'normalization' do
    describe 'address' do
      it { is_expected.to normalize_attribute(:address).from("  Line 1  \n    Line 2    \n    ").to("Line 1\nLine 2")}
      [:city, :state, :postal_code, :country].each do |attr_name|
        it { is_expected.to normalize_attribute(attr_name) }
      end
    end
  end

  #═════════════════════════════════════════════════════════════════════════════════════════════════
  describe 'parts and lines' do
    it do
      address = Address.new(
        address: '10 Some Road',
        city: 'Watford', state: 'HRT', postal_code: 'WD25 9JZ',
        country: 'United Kingdom'
      )
      expect(address.parts).to eq([
        '10 Some Road',
        'Watford',
        'Hertfordshire',
        'WD25 9JZ',
        'United Kingdom'
      ])
      expect(address.lines).to eq([
        '10 Some Road',
        'Watford WD25 9JZ',
        'United Kingdom'
      ])
      expect(address.city_line).to eq('Watford WD25 9JZ')
      expect(address.city_state_name).to eq('Watford, Hertfordshire')
    end
  end

  describe '#city_state/#city_state_country' do
    context "when address doesn't have a state" do
      let(:user) { User.create }
      subject { user.build_physical_address(address: '123', city: 'Stockholm', country_name: 'Sweden') }
      it { expect(subject.city_state_code).to    eq('Stockholm') }
      it { expect(subject.city_state_name).to    eq('Stockholm') }
      it { expect(subject.city_state_country).to eq('Stockholm, Sweden') }
    end
    context "when address has a state abbrevitation in :state field" do
      let(:user) { User.create }
      subject { user.build_physical_address(address: '123', city: 'Nelspruit', state: 'MP', country_name: 'South Africa') }
      it { expect(subject.state_code).to         eq('MP') }
      it { expect(subject.city_state_code).to    eq('Nelspruit, MP') }
      it { expect(subject.city_state_name).to    eq('Nelspruit, Mpumalanga') }
      it { expect(subject.city_state_country).to eq('Nelspruit, Mpumalanga, South Africa') }
    end
    context "when address has a state abbrevitation in :state field (Denmark)" do
      let(:user) { User.create }
      subject { user.build_physical_address(address: '123', city: 'Copenhagen', state: '84', country_name: 'Denmark') }
      it { expect(subject.city_state_name).to    eq('Copenhagen, Hovedstaden') }
      it { expect(subject.state_name).to         eq('Hovedstaden') }
    end

    # United States
    context "when address has a state name entered for :state instead of an abbreviation" do
      let(:user) { User.create }
      subject { user.build_physical_address(address: '123', city: 'Ocala', state: 'Florida', country_name: 'United States') }
      it { expect(subject.city_state_code).to    eq('Ocala, FL') }
      it { expect(subject.city_state_name).to    eq('Ocala, Florida') }
      it { expect(subject.city_state_country).to eq('Ocala, Florida, United States') }
    end
    context "when address has a state abbrevitation in :state field" do
      let(:user) { User.create }
      subject { user.build_physical_address(address: '123', city: 'Ocala', state: 'FL', country_name: 'United States') }
      it { expect(subject.city_state_code).to    eq('Ocala, FL') }
      it { expect(subject.city_state_name).to    eq('Ocala, Florida') }
      it { expect(subject.city_state_country).to eq('Ocala, Florida, United States') }
    end
    context "when address has a state name entered for :state instead of an abbreviation, but state is for different country" do
      let(:user) { User.create }
      subject { user.build_physical_address(address: '123', city: 'Ocala', state: 'FL', country_name: 'Denmark') }
      it { expect(subject.city_state_code).to    eq('Ocala, FL') }
      it { expect(subject.city_state_name).to    eq('Ocala, FL') }
      it { expect(subject.city_state_country).to eq('Ocala, FL, Denmark') }
    end
  end

  describe 'same_as?' do
    it 'should be true when country is only present attribute and it matches' do
      expect(Address.new(country: 'United States')).to be_same_as(
      Address.new(country: 'United States'))
    end
    it 'should be true when country and state are only present attributes and they match' do
      expect(Address.new(state: 'Washington', country: 'United States')).to be_same_as(
      Address.new(state: 'Washington', country: 'United States'))
    end
    it "not should be true when address attribute doesn't match" do
      expect(Address.new(address: '123 C St.', state: 'Washington', country: 'United States')).not_to be_same_as(
      Address.new(address: '444 Z St.', state: 'Washington', country: 'United States'))
    end
  end

  #═════════════════════════════════════════════════════════════════════════════════════════════════
  describe '#carmen_country' do
    it { expect(Address.new(country: 'South Africa').carmen_country).to be_a Carmen::Country }
  end
  describe '#carmen_state' do
    it { expect(Address.new(country: 'United States', state: 'OH!').carmen_state).to be_nil }
    it { expect(Address.new(country: 'United States', state: 'OH').carmen_state).to be_a Carmen::Region }
    it { expect(Address.new(country: 'United States', state: 'AA').carmen_state).to be_a Carmen::Region }
    it { expect(Address.new(country: 'South Africa',  state: 'MP').carmen_state).to be_a Carmen::Region }
  end

  describe '#states_for_country, etc.' do
    it { expect(Address.new(country: 'United States').states_for_country.map(&:code)).to include 'AA' }
    it { expect(Address.new(country: 'United States').states_for_country.map(&:name)).to include 'Ohio' }
    it { expect(Address.new(country: 'United States').states_for_country.map(&:name)).to include 'District of Columbia' }
    it { expect(Address.new(country: 'United States').states_for_country.map(&:name)).to include 'Puerto Rico' }
    it { expect(Address.new(country: 'South Africa').states_for_country.map(&:name)).to include 'Mpumalanga' }
    it { expect(Address.new(country: 'Kenya').states_for_country.typed('province')).to be_empty }
    # At the time of this writing, it doesn't look like Carmen has been updated to
    # include the 47 counties listed under https://en.wikipedia.org/wiki/ISO_3166-2:KE.
    #it { Address.new(country: 'Kenya').states_for_country.map(&:name).should include 'Nyeri' }
    it { expect(Address.new(country: 'Denmark').state_options).to be_many }
    it { expect(Address.new(country: 'Denmark').state_options.map(&:name)).to include 'Sjælland' }
    it { expect(Address.new(country: 'Denmark').state_possibly_included_in_postal_address?).to eq false }

    # Auckland (AUK) is a subregion of the North Island (N) subregion
    it { expect(Address.new(country: 'New Zealand').state_options.map(&:code)).to include 'AUK' }
    it { expect(Address.new(country: 'New Zealand').state_options.map(&:code)).not_to include 'N' }
    # Chatham Islands Territory (CIT) is a top-level region
    it { expect(Address.new(country: 'New Zealand').state_options.map(&:code)).to include 'CIT' }

    # Abra (ABR) is a subregion of the Cordillera Administrative Region (CAR) (15) subregion
    it { expect(Address.new(country: 'Philippines').state_options.map(&:code)).to include 'ABR' }
    it { expect(Address.new(country: 'Philippines').state_options.map(&:code)).not_to include '15' }
    # National Capital Region (00) is a top-level region
    it { expect(Address.new(country: 'Philippines').state_options.map(&:code)).to include '00' }

    # https://en.wikipedia.org/wiki/Provinces_of_Indonesia
    #   The provinces are officially grouped into seven geographical units
    # Jawa Barat (JB) is a subregion of the Jawa (JW) subregion
    it { expect(Address.new(country: 'Indonesia').state_options.map(&:code)).to include 'JB' }
    it { expect(Address.new(country: 'Indonesia').state_options.map(&:code)).not_to include 'JW' }
    # The province is not called "Jakarta Raya" according to
    # https://en.wikipedia.org/wiki/ISO_3166-2:ID and https://en.wikipedia.org/wiki/Jakarta — it's
    # called 'DKI Jakarta', which is short for 'Daerah Khusus Ibukota Jakarta' ('Special Capital
    # City District of Jakarta'),
    it { expect(Address.new(country: 'Indonesia').state_options.map(&:name)).to include 'DKI Jakarta' }

    # At the time of this writing, it doesn't look like Carmen has been updated to reflect the new 18
    # regions of France.
    it { expect(Address.new(country: 'France').state_options.size).to eq 0 }
    #it { Address.new(country: 'France').state_options.size.should eq 18 }
    #it { Address.new(country: 'France').state_options.map(&:name).should include 'Auvergne-Rhône-Alpes' }
  end

  #═════════════════════════════════════════════════════════════════════════════════════════════════
  describe 'associations' do
    # To do (or maybe not even necessary—seems to work with only the has_one side of the association):
    #describe 'when we have a polymorphic belongs_to :addressable in Address' do
    #belongs_to :addressable, :polymorphic => true

    describe 'Company has_one :address' do
      let(:company) { Company.create }

      it do
        expect(company.address).to eq(nil)
        address = company.build_address(address: '1')
        company.save!
        expect(company.reload.address).to eq(address)
        expect(address.addressable).to eq(company)
      end

    end

    describe 'User has_many :addresses' do
      let(:user) { User.create }

      it do
        expect(user.addresses).to eq([])
        address_1 = user.addresses.build(address: '1')
        address_2 = user.addresses.build(address: '2')
        user.save!; user.reload
        expect(user.addresses).to eq([address_1, address_2])
      end

      specify 'should able to set and retrieve a specific address by type (shipping or billing)' do
        physical_address = user.build_physical_address(address: 'Physical')
        shipping_address = user.build_shipping_address(address: 'Shipping')
        billing_address  = user.build_billing_address( address: 'Billing')
        vacation_address = user.addresses.build(address: 'Vacation', :address_type => 'Vacation')
        user.save!; user.reload
        expect(user.physical_address).to eq(physical_address)
        expect(user.shipping_address).to eq(shipping_address)
        expect(user.billing_address). to eq(billing_address)
        expect(user.addresses.to_set).to eq([physical_address, shipping_address, billing_address, vacation_address].to_set)
        expect(physical_address.addressable).to eq(user)
        expect(shipping_address.addressable).to eq(user)
        expect(billing_address .addressable).to eq(user)
      end
    end

    describe 'Employee belongs_to :home_address' do
      subject!(:employee) { Employee.create! }

      it do
        expect(employee.home_address).to eq(nil)
        expect(employee.work_address).to eq(nil)
        home_address = employee.build_home_address(address: '1')
        work_address = employee.build_work_address(address: '2')
        employee.save!
        expect(employee.reload.home_address).to eq(home_address)
        expect(employee.reload.work_address).to eq(work_address)
        expect(home_address.employee_home).to eq(employee)
        expect(work_address.employee_work).to eq(employee)
      end
    end

    describe 'Child belongs_to :secret_hideout' do
      subject!(:child) { Child.create! }

      it do
        expect(child.address).       to eq(nil)
        expect(child.secret_hideout).to eq(nil)
        address        = child.build_address(address: '2')
        secret_hideout = child.build_secret_hideout(address: '1')
        child.save!
        expect(child.reload.address).       to eq(address)
        expect(child.reload.secret_hideout).to eq(secret_hideout)
        expect(address.       child).                   to eq(child)
        expect(secret_hideout.child_for_secret_hideout).to eq(child)
      end
    end
  end
end
