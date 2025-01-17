require 'spec_helper'

describe Address, type: :model do
  def klass
    described_class
  end

  describe AddressWithNameOnly do
    it 'using attribute alias' do
      expect(klass.state_name_attribute).to eq :state
      expect(klass.country_name_attribute).to eq :country

      address = klass.new(country_code: 'AE')
      expect(address.country_code).to eq 'AE'
      expect(address.country     ).to eq 'United Arab Emirates'

      address = klass.new(country_name: 'Iceland')
      expect(address.country_name).to eq 'Iceland'
      expect(address.country     ).to eq 'Iceland'

      address = klass.new(country: 'United States', state_code: 'ID')
      expect(address.state_code).to eq 'ID'
      expect(address.state     ).to eq 'Idaho'

      address = klass.new(country: 'United States', state_name: 'Idaho')
      expect(address.state_name).to eq 'Idaho'
      expect(address.state     ).to eq 'Idaho'
    end
  end

  describe AddressWithCodeOnly do
    it 'using attribute alias' do
      expect(klass.state_code_attribute).to eq :state
      expect(klass.country_code_attribute).to eq :country

      address = klass.new(country_code: 'AE')
      expect(address.country_code).to eq 'AE'
      expect(address.country     ).to eq 'AE'

      address = klass.new(country_name: 'Iceland')
      expect(address.country_name).to eq 'Iceland'
      expect(address.country     ).to eq 'IS'

      address = klass.new(country: 'US', state_code: 'ID')
      expect(address.state_code).to eq 'ID'
      expect(address.state     ).to eq 'ID'

      address = klass.new(country: 'US', state_name: 'Idaho')
      address.state_name = 'Idaho'
      expect(address.state_name).to eq 'Idaho'
      expect(address.state     ).to eq 'ID'
    end
  end

  #═════════════════════════════════════════════════════════════════════════════════════════════════
  describe 'setting to invalid values' do
    let(:address) { klass.new }

    # Even if it's an unrecognized country/state code/name, we need to write the value to the
    # attribute (in memory only), so that it can be validated and shown in the form if it
    # re-rendered.  To prevent invalid values from being persisted, you should add validations.
    it do
      address = Address.new
      address.country = 'Fireland'
      expect(address.country_name).to eq('Fireland')
      expect(address.country_code).to eq(nil)

      address = Address.new
      address.country_code = 'FL'
      expect(address.country_name).to eq(nil)
      expect(address.country_code).to eq('FL')

      address = Address.new(country: 'United States')
      address.state = 'New Zork'
      expect(address.state_name).to eq('New Zork')
      expect(address.state_code).to eq(nil)

      address = Address.new(country: 'United States')
      address.state_code = 'NZ'
      expect(address.state_name).to eq(nil)
      expect(address.state_code).to eq('NZ')
    end

    describe AddressWithCodeOnly do
      it do
        address = klass.new
        address.country = 'Fireland'
        expect(address.country_name).to eq(nil)
        expect(address.country_code).to eq('Fireland')

        address = klass.new
        address.country_name = 'Fireland'
        expect(address.country_name).to eq(nil) # No attribute to store it in
        expect(address.country_code).to eq(nil)

        address = klass.new
        address.country_code = 'FL'
        expect(address.country_name).to eq(nil)
        expect(address.country_code).to eq('FL')

        address = klass.new(country: 'United States')
        address.state = 'New Zork'
        expect(address.state_name).to eq(nil)
        expect(address.state_code).to eq('New Zork')

        address = klass.new(country: 'United States')
        address.state_name = 'New Zork'
        expect(address.state_name).to eq(nil) # No attribute to store it in
        expect(address.state_code).to eq(nil)

        address = klass.new(country: 'United States')
        address.state_code = 'NZ'
        expect(address.state_name).to eq(nil)
        expect(address.state_code).to eq('NZ')
      end
    end

    describe AddressWithNameOnly do
      it do
        address = klass.new
        address.country = 'Fireland'
        expect(address.country_name).to eq('Fireland')
        expect(address.country_code).to eq(nil)

        address = klass.new
        address.country_name = 'Fireland'
        expect(address.country_name).to eq('Fireland')
        expect(address.country_code).to eq(nil)

        address = klass.new
        address.country_code = 'FL'
        expect(address.country_name).to eq(nil)
        expect(address.country_code).to eq(nil) # No attribute to store it in

        address = klass.new(country: 'United States')
        address.state = 'New Zork'
        expect(address.state_name).to eq('New Zork')
        expect(address.state_code).to eq(nil)

        address = klass.new(country: 'United States')
        address.state_name = 'New Zork'
        expect(address.state_name).to eq('New Zork')
        expect(address.state_code).to eq(nil)

        address = klass.new(country: 'United States')
        address.state_code = 'NZ'
        expect(address.state_name).to eq(nil)
        expect(address.state_code).to eq(nil) # No attribute to store it in
      end
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
      it { expect(subject.country_name).to eq('US') }
    end

    specify 'setting to unknown country' do
      address.country = 'Fireland'
      expect(address.country_name).to eq 'Fireland'
      expect(address.country_code).to eq nil

      address.country = 'Northern Ireland'
      expect(address.country_name).to eq 'Northern Ireland'
      expect(address.country_code).to eq nil

      address.country = 'Estados Unidos'
      expect(address.country_name).to eq 'Estados Unidos'
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
      address.country = 'FL'
      expect(address.country_name).to eq 'FL'
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

  describe 'setting state' do
    # Uses find_carmen_state, which finds by name, falling back to finding by code.
    describe 'setting state_name_attribute' do
      before {
        expect(Address.state_code_attribute).to eq :state_code
        expect(Address.state_name_attribute).to eq :state
      }

      context "setting state_name_attribute to code" do
        subject { Address.new(state: 'FL', country_name: 'United States') }
        it { expect(subject.state_code).to eq('FL') }
      end

      context "setting state_name_attribute to name" do
        subject { Address.new(state: 'Florida', country_name: 'United States') }
        it { expect(subject.state_code).to eq('FL') }
      end
    end

    # Unlike {state_name_attribute}=, which falls back to finding by code, {state_code_attribute}=
    # _only_ looks up by code by default.
    describe 'setting state_code_attribute' do
      subject { Address.new(state_code: input, country_name: 'United States') }

      before {
        expect(Address.state_code_attribute).to eq :state_code
        expect(Address.state_name_attribute).to eq :state

      }
      around(:example) { |example|
        validate_code = Address.state_config[:validate_code]
        Address.state_config[:validate_code] = true
        example.run
        Address.state_config[:validate_code] = validate_code
      }

      context "setting state_code_attribute to code" do
        let(:input) { 'FL' }
        it { expect(subject.state_code).to eq(input) }
        it { expect(subject.carmen_state&.code).to eq('FL') }
        it { expect(subject).to allow_values(input).for(:state_code) }
      end

      context "setting state_code_attribute to name: doesn't find by default" do
        let(:input) { 'Florida' }
        subject { Address.new(state_code: input, country_name: 'United States') }
        it { expect(subject.state_code).to eq(input) }
        it { expect(subject.carmen_state&.code).to eq(nil) }
        it { expect(subject).to_not allow_values(input).for(:state_code).with_message('is not a valid option for United States') }

        context "when state_config[:on_unknown] returns :find_by_name" do
          before {
            @orig = Address.state_config[:on_unknown]
            Address.state_config[:on_unknown] = Proc.new { :find_by_name }
          }
          after { Address.state_config[:on_unknown] = @orig }
          it { expect(subject.carmen_state&.code).to eq('FL') }
          it { expect(subject.state_code).to eq('FL') }
          it { expect(subject).to allow_values(input).for(:state_code) }
        end
      end
    end
  end

  #═════════════════════════════════════════════════════════════════════════════════════════════════
  describe 'validations' do
    it do
      expect(AddressConcern::Address.instance_method(:validate_state_for_country)).to be_a UnboundMethod
    end
  end

  #═════════════════════════════════════════════════════════════════════════════════════════════════

  describe 'present?' do
    let(:address) { Address.new }
    [:address, :city, :state, :postal_code].each do |attr_name|
      it "should be true when #{attr_name} (and only #{attr_name}) is present" do
        address.write_attribute attr_name, 'something'
        expect(address).to be_present
      end
    end
    it "should be true when country (and only country) is present" do
      expect(Address.new(country: 'Latvia')).to be_present
    end
  end

  #describe 'normalization' do
  #  describe 'address' do
  #    it { is_expected.to normalize_attribute(:address).from("  Line 1  \n    Line 2    \n    ").to("Line 1\nLine 2")}
  #    [:city, :state, :postal_code, :country].each do |attr_name|
  #      it { is_expected.to normalize_attribute(attr_name) }
  #    end
  #  end
  #end

  #═════════════════════════════════════════════════════════════════════════════════════════════════
  describe 'address, address_lines' do
    describe Address do
      it do
        expect(klass.multi_line_street_address?).to eq true

        address = klass.new(address: str = 'Line 1')
        expect(address.address).to eq str

        address = klass.new(address: str = "Line 1\nLine 2\nLine 3")
        expect(address.address).to eq str
        expect(address.street_address_lines).to eq [
          'Line 1',
          'Line 2',
          'Line 3',
        ]
      end
    end

    describe AddressWithSeparateAddressColumns do
      it do
        expect(klass.multi_line_street_address?).to eq false

        address = klass.new(
          address_1: 'Line 1',
          address_2: 'Line 2',
          address_3: 'Line 3',
        )
        expect(address.address_1).to eq 'Line 1'
        expect(address.address_2).to eq 'Line 2'
        expect(address.address_3).to eq 'Line 3'
        expect(address.street_address_lines).to eq [
          'Line 1',
          'Line 2',
          'Line 3',
        ]
      end
    end
  end

  #═════════════════════════════════════════════════════════════════════════════════════════════════
  describe '#inspect' do
    it do
      address = Address.new(
        address: '10 Some Road',
        city: 'Watford', state: 'HRT', postal_code: 'WD25 9JZ',
        country: 'United Kingdom'
      )
      expect(address.inspect).to eq \
        "<Address new: address: 10 Some Road, city: Watford, state: Hertfordshire, state_code: HRT, postal_code: WD25 9JZ, country: United Kingdom, country_code: GB>"
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
    context "when address has a state name instead of code entered for state_name, and state is for different country" do
      let(:user) { User.create }
      # Internally, it sees: unknown state code 'FL'
      subject { user.build_physical_address(address: '123', city: 'Ocala', state_code: 'FL', country_name: 'Denmark') }
      it do
        expect(subject.state_code).         to eq('FL')
        expect(subject.state_name).         to eq(nil)
        expect(subject.city_state_code).    to eq('Ocala, FL')
        expect(subject.city_state_name).    to eq('Ocala')
        expect(subject.city_state_country). to eq('Ocala, Denmark')
      end
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
    it { expect(Address.new(country: 'France').state_options.size).to eq 26 }
    it { expect(Address.new(country_name: 'France').state_options.map(&:name)).to include 'Auvergne-Rhône-Alpes' }
    #it { Address.new(country: 'France').state_options.size.should eq 18 }
    #it { Address.new(country: 'France').state_options.map(&:name).should include 'Auvergne-Rhône-Alpes' }

    context 'for a country without states data (Aruba)' do
      subject { Address.new(country_name: 'Aruba') }
      it do
        expect(subject.states_for_country).to be_empty
        expect(subject.states_for_country).to be_a Carmen::RegionCollection
        expect(subject.states_for_country.coded('Roo')).to eq nil
        expect(subject.country_with_states?).to eq false
      end
    end

    context 'with an invalid country code (ZZ)' do
      subject { Address.new(country_code: 'ZZ') }
      it do
        expect(subject.states_for_country).to be_empty
        expect(subject.states_for_country).to be_a Carmen::RegionCollection
        expect(subject.states_for_country.coded('Roo')).to eq nil
        expect(subject.country_with_states?).to eq false
      end
    end
  end

  #═════════════════════════════════════════════════════════════════════════════════════════════════
  describe 'associations' do
    # To do (or maybe not even necessary—seems to work with only the has_one side of the association):
    #describe 'when we have a polymorphic belongs_to :addressable in Address' do
    #belongs_to :addressable, polymorphic: true

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
        vacation_address = user.addresses.build(address: 'Vacation', address_type: 'Vacation')
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
