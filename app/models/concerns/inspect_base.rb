# frozen_string_literal: true

module AddressConcern
module InspectBase
  def inspect_base(*_items, class: true, id: true)
    items = _items.map { |item|
      if item.is_a?(Hash)
        item.map { |k, v|
          "#{k}: #{v}"
        }.join(', ')
      elsif item.respond_to?(:to_proc) && item.to_proc.arity <= 0
        item.to_proc.(self)
      else
        item.to_s
      end
    }

    _class = binding.local_variable_get(:class)
    _id    = binding.local_variable_get(:id)

    '<' +
    [
      (_class == true ? self.class : _class),
      ("#{self.id || 'new'}:" if _id),
    ].join(' ') + ' ' +
    [
      *items,
    ].filter_map(&:presence).map(&:to_s).join(', ') +
    '>'
  end
end
end
