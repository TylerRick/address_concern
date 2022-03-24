if false
  require 'attribute_normalizer'
  #require 'facets/string/cleanlines'

  require_relative '../core_extensions/string/cleanlines'
  using String::Cleanlines

  AttributeNormalizer.configure do |config|
    config.normalizers[:cleanlines] = ->(input, options) {
      input.to_s.cleanlines.to_a.join("\n")
    }
  end
end
