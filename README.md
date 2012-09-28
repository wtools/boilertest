Use this gem to simplify your functional tests:

<pre>
  <code>
    class FooControllerTest &lt; ActionController::TestCase
      def self.editable_attributes
        {
          name: -&gt;(asset){ Faker::Lorem.words.last }
        }
      end

      prepare_stuff = Proc.new do
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
  </code>
</pre>

<strong>TODO</strong>: write tests '>_<