require 'factory_girl/syntax/methods'

module Boilertest
  module FixtureFile
    def fixture_file(filename)
      return '' if filename == ''
      file_path = File.join(Rails.root, 'test', 'fixtures', filename)
      File.read(file_path).strip
    end
  end

  class ActionController::TestCase
    include FixtureFile
    include Devise::TestHelpers
    include FactoryGirl::Syntax::Methods
    
    class << self
      def should_perform_action action, model, opts, &block
        should_fail = %w(unauthorized unprocessable_entity).include?(opts[action].to_s)
        should "#{should_fail ? 'not ' : ''}create a new #{model.to_s.classify}" do
          @count = should_fail ? 0 : 1
          @should_fail = should_fail
          self.instance_eval(&block)
        end
      end

      def params_for model
        attrs = FactoryGirl.attributes_for model
        FactoryGirl.build(model).class.reflections.each_pair do |key, r|
          next unless attrs[key]
          val = attrs.delete(key)
          pkey = r.primary_key_column.name
          case r.macro
          when :has_many
            attrs[r.association_foreign_key.pluralize] = val.map{|a| a.send pkey}
          when :belongs_to
            attrs[r.association_foreign_key] = val.send pkey
          end
        end
        attrs
      end

      def modify_values asset, editable_attributes=nil
        out = {}
        editable_attributes ||= []
        editable_attributes = [editable_attributes] unless editable_attributes.is_a?(Array)
        editable_attributes.each do |k|
          case k
          when String
            v = asset.send(k)
            out[k] = case v
            when String
              v.reverse
            when Fixnum
              -v
            else
              v
            end
          when Hash
            k.each_pair do |kk, vv|
              out[kk] = vv.call(asset)
            end
          end
        end
        out
      end

      def test_default_behaviour model, responses, opts={}
        custom_setup = opts.delete(:setup)
        editable_attributes = opts.delete(:editable_attributes)

        prepare_setup = Proc.new do
          if custom_setup
            setup &custom_setup
          end
          setup do
            @extra_url_params ||= {}
            @asset ||= create(model)
          end
        end

        %w(index new).each do |action|
          next unless responses.key?(action.intern)
          context "GET on :#{action}" do
            prepare_setup.call
            setup { get action.intern, @extra_url_params }
            should respond_with responses[action.intern]
          end
        end

        %w(show edit).each do |action|
          next unless responses.key?(action.intern)
          context "GET on :#{action}" do
            prepare_setup.call
            setup do
              get action.intern, {id: @asset.to_param}.update(@extra_url_params)
            end
            should respond_with responses[action.intern]
          end
        end

        if responses.key?(:create)
          context 'POST on :create' do
            prepare_setup.call
            should_perform_action :create, model, responses do
              assert_difference "#{model.to_s.classify}.count", @count do
                post :create, {model => self.class.params_for(model)}.update(@extra_url_params)
                assert_response responses[:create]
                if :unprocessable_entity == responses[:create]
                  self.assert_template :new
                end
              end
            end
          end
        end

        if responses.key?(:update)
          context 'PUT on :update' do
            prepare_setup.call
            setup do
              @modified_values = self.class.modify_values(@asset, editable_attributes)
              put :update, {id: @asset.to_param, model => @modified_values}.update(@extra_url_params)
            end

            should respond_with responses[:update]
            should_fail = %w(unauthorized unprocessable_entity).include? responses[:update].to_s
            unless should_fail
              should "update values" do
                @modified_values.each_pair do |k,v|
                  assert_equal v, @asset.reload.send(k)
                end
              end
            end
            if :unprocessable_entity ==  responses[:update]
              should 'use right template' do
                self.assert_template :edit
              end
            end
          end
        end
      end

      def test_default_behaviour_for_user user, model, responses, opts={}
        if user
          when_logged_in as: user do
            test_default_behaviour model, responses, opts
          end
        else
          context 'When not logged in' do
            test_default_behaviour model, responses, opts
          end
        end
      end

      def when_logged_in opts={}, &block
        title = opts[:label] || opts[:as].to_s
        context "when logged in#{title ? " as #{title}" : ''}" do
          setup do
            traits = opts[:traits] || []
            @current_user = if opts.key? :as
              case as = opts[:as]
                when String then eval as
                # Note: instance_exec accepts lambdas with zero arity,
                # instance_eval does not. Do not change it!
                when Proc then instance_exec &as
                when Symbol then FactoryGirl.create(as, *traits)
              end
            else
              FactoryGirl.create :user, *traits
            end
            sign_in @current_user
          end
          merge_block(&block)
        end
      end
    end
  end
end
