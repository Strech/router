require 'lotus/utils/string'
require 'lotus/utils/path_prefix'
require 'lotus/utils/class_attribute'

module Lotus
  module Routing
    class Resource
      # Action for RESTful resource
      #
      # @since 0.1.0
      #
      # @api private
      #
      # @see Lotus::Router#resource
      class Action
        include Utils::ClassAttribute

        # Ruby namespace where lookup for default subclasses.
        #
        # @api private
        # @since 0.1.0
        class_attribute :namespace
        self.namespace = Resource

        # Accepted HTTP verb
        #
        # @api private
        # @since 0.1.0
        class_attribute :verb
        self.verb = :get

        # Generate an action for the given router
        #
        # @param router [Lotus::Router]
        # @param action [Lotus::Routing::Resource::Action]
        # @param options [Hash]
        #
        # @api private
        #
        # @since 0.1.0
        def self.generate(router, action, options)
          class_for(action).new(router, options)
        end

        # Initialize an action
        #
        # @param router [Lotus::Router]
        # @param options [Hash]
        # @param blk [Proc]
        #
        # @api private
        #
        # @since 0.1.0
        def initialize(router, options, &blk)
          @router, @options = router, options
          generate(&blk)
        end

        # Generate an action for the given router
        #
        # @param blk [Proc]
        #
        # @api private
        #
        # @since 0.1.0
        def generate(&blk)
          @router.send verb, path, to: endpoint, as: as
          instance_eval(&blk) if block_given?
        end

        # Resource name
        #
        # @api private
        # @since 0.1.0
        #
        # @example
        #   require 'lotus/router'
        #
        #   Lotus::Router.new do
        #     resource 'identity'
        #   end
        #
        #   # 'identity' is the name passed in the @options
        def resource_name
          @options[:name]
        end

        # Path prefix
        #
        # @api private
        # @since 0.1.0
        def prefix
          @prefix ||= Utils::PathPrefix.new @options[:prefix]
        end

        private
        # Load a subclass, according to the given action name
        #
        # @param action [String] the action name
        #
        # @example
        #   Lotus::Routing::Resource::Action.send(:class_for, 'New') # =>
        #     Lotus::Routing::Resource::New
        #
        # @api private
        # @since 0.1.0
        def self.class_for(action)
          Utils::Class.load!(Utils::String.new(action).classify, namespace)
        end

        # Accepted HTTP verb
        #
        # @see Lotus::Routing::Resource::Action.verb
        #
        # @api private
        # @since 0.1.0
        def verb
          self.class.verb
        end

        # The URL relative path
        #
        # @example
        #   require 'lotus/router'
        #
        #   Lotus::Router.new do
        #     resources 'flowers'
        #   end
        #
        #   # It will generate paths like '/flowers', '/flowers/:id' ..
        #
        # @api private
        # @since 0.1.0
        def path
          prefix.join(rest_path)
        end

        # The name of the action within the whole context of the router.
        #
        # @example
        #   require 'lotus/router'
        #
        #   Lotus::Router.new do
        #     resources 'flowers'
        #   end
        #
        #   # It will generate named routes like :flowers, :new_flowers ..
        #
        # @api private
        # @since 0.1.0
        def as
          prefix.relative_join(named_route, '_').to_sym
        end

        # The name of the RESTful action.
        #
        # @example
        #   'index'
        #   'new'
        #   'create'
        #
        # @api private
        # @since 0.1.0
        def action_name
          self.class.name.split('::').last.downcase
        end

        # A string that represents the endpoint to be loaded.
        # It is composed by controller and action name.
        #
        # @see Lotus::Routing::Resource::Action#separator
        #
        # @example
        #   'flowers#index'
        #
        # @api private
        # @since 0.1.0
        def endpoint
          [ resource_name, action_name ].join separator
        end

        # Separator between controller and action name
        #
        # @see Lotus::Routing::EndpointResolver#separator
        #
        # @example
        #   '#' # default
        #
        # @api private
        # @since 0.1.0
        def separator
          @options[:separator]
        end
      end

      # Collection action
      # It implements #collection within a #resource block.
      #
      # @api private
      # @since 0.1.0
      # @see Lotus::Router#resource
      class CollectionAction < Action
        def generate(&blk)
          instance_eval(&blk) if block_given?
        end

        protected
        def method_missing(m, *args, &blk)
          verb, path, _ = m, *args
          @router.send verb, path(path), to: endpoint(path), as: as(path)
        end

        private
        def path(path)
          prefix.join(path)
        end

        def endpoint(path)
          "#{ resource_name }##{ path }"
        end

        def as(path)
          Utils::PathPrefix.new(path).relative_join(resource_name, '_').to_sym
        end
      end

      # Collection action
      # It implements #member within a #resource block.
      #
      # @api private
      # @since 0.1.0
      # @see Lotus::Router#resource
      class MemberAction < CollectionAction
      end

      # New action
      #
      # @api private
      # @since 0.1.0
      # @see Lotus::Router#resource
      class New < Action
        private
        def rest_path
          "/#{ resource_name }/new"
        end

        def named_route
          "new_#{ resource_name }"
        end
      end

      # Create action
      #
      # @api private
      # @since 0.1.0
      # @see Lotus::Router#resource
      class Create < Action
        self.verb = :post

        private
        def rest_path
          "/#{ resource_name }"
        end

        def named_route
          resource_name
        end
      end

      # Show action
      #
      # @api private
      # @since 0.1.0
      # @see Lotus::Router#resource
      class Show < Action
        private
        def rest_path
          "/#{ resource_name }"
        end

        def named_route
          resource_name
        end
      end

      # Edit action
      #
      # @api private
      # @since 0.1.0
      # @see Lotus::Router#resource
      class Edit < Action
        private
        def rest_path
          "/#{ resource_name }/edit"
        end

        def named_route
          "edit_#{ resource_name }"
        end
      end

      # Update action
      #
      # @api private
      # @since 0.1.0
      # @see Lotus::Router#resource
      class Update < Action
        self.verb = :patch

        private
        def rest_path
          "/#{ resource_name }"
        end

        def named_route
          resource_name
        end
      end

      # Destroy action
      #
      # @api private
      # @since 0.1.0
      # @see Lotus::Router#resource
      class Destroy < Action
        self.verb = :delete

        private
        def rest_path
          "/#{ resource_name }"
        end

        def named_route
          resource_name
        end
      end
    end
  end
end
