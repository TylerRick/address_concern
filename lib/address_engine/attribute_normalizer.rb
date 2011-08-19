require 'attribute_normalizer'
require 'facets/string/cleanlines'

AttributeNormalizer.configure do |config|
  config.normalizers[:cleanlines] = lambda do |input, options|
    input.to_s.cleanlines.to_a.join("\n")
  end
end

