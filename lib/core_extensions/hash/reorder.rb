module Hash::Reorder
  refine Hash do
    def reorder(*order)
      slice(*order).merge except(*order)
    end

    def reorder!(*order)
      replace(reorder(*order))
    end
  end
end
