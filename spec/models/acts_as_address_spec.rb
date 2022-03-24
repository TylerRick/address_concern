require 'spec_helper'

describe 'acts_as_address' do
  def klass
    subject.class
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
      expect(klass.state_name_attribute).to eq  nil
      expect(klass.state_code_attribute).to eq 'state'
      expect(klass.country_name_attribute).to eq nil
      expect(klass.country_code_attribute).to eq 'country'
    end
  end

  describe 'name_attribute == code_attribute' do
    let(:klass) do
      Class.new(ApplicationRecord) do
        acts_as_address(
          country: {
            name_attribute: 'country',
            code_attribute: 'country',
          }
        )
      end
    end
    let(:address) { klass.new }
    it 'name takes precedence' do
      expect(klass.country_name_attribute).to eq 'country'
      expect(klass.country_code_attribute).to eq nil
    end
  end
end

