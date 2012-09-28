Use this gem to simplify your functional tests:

class FooControllerTest < ActionController::TestCase
  def self.editable_attributes
    {
      name: ->(asset){ Faker::Lorem.words.last }
    }
  end

  prepare_region = Proc.new do
    @bar = Bar.new
    @asset = Foo.new(name: "Babar", bar: bar)
    @extra_url_params = {parent_id: @bar.slug} 
  end

  test_default_behaviour_for_user nil, :language, {
    index:  :unauthorized,
    new:    :unauthorized,
    create: :unauthorized,
    edit:   :unauthorized,
    update: :unauthorized
  }, {
    editable_attributes: editable_attributes,
    setup: prepare_stuff
  }

  test_default_behaviour_for_user :user, :language, {
    index:  :unauthorized,
    new:    :unauthorized,
    create: :unauthorized,
    edit:   :unauthorized,
    update: :unauthorized
  }, {
    editable_attributes: editable_attributes,
    setup: prepare_stuff
  }
end