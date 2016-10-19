class WidgetActivity < Widget
  store :settings, accessors: [:position, :width], coder: JSON
end
