require 'cache_method'

module Azure
  module Armrest
    class ResourceProviderService < ArmrestService
      # The provider used in http requests. The default is 'Microsoft.Resources'
      attr_reader :provider

      # The amount of time in seconds to cache certain methods. The default is 24 hours.
      @cache_time = 24 * 60 * 60

      class << self
        # Get or set the cache time for all methods. The default is 24 hours.
        attr_accessor :cache_time
      end

      # Creates and returns a new ResourceProviderService object.
      #
      # Note that many ResourceProviderService instance methods are cached. You
      # can set the cache_time for certain methods in the constructor, but keep in
      # mind that it is a global setting for the class. You can also set this
      # at the class level if desired. The default cache time is 24 hours.
      #
      # You can also set the provider. The default is 'Microsoft.Resources'.
      #
      def initialize(_armrest_configuration, options = {})
        super

        @provider = options[:provider] || 'Microsoft.Resources'

        if options[:cache_time]
          @cache_time = options[:cache_time]
          self.class.send(:cache_time=, @cache_time)
        end

        set_service_api_version(options, 'resourceGroups')
      end

      # List all the providers for the current subscription. The results of
      # this method are cached.
      #
      def list
        _list.map{ |hash| Azure::Armrest::ResourceProvider.new(hash) }
      end

      def _list
        response = rest_get(build_url)
        JSON.parse(response)["value"]
      end
      private :_list

      # Cannot directly cache list method, because Marshal used by chche_method
      # cannot dump anonymous class, including the ones derived from Azure::Armrest::BaseModel
      # Same applies to other cached methods in this class
      cache_method(:_list, cache_time)

      # Return information about a specific +namespace+ provider. The results
      # of this method are cached.
      #
      def get(namespace)
        Azure::Armrest::ResourceProvider.new(_get(namespace))
      end

      def _get(namespace)
        url = build_url(namespace)
        rest_get(url).body
      end
      private :_get

      cache_method(:_get, cache_time)

      # Returns an array of geo-locations for the given +namespace+ provider.
      # The results of this method are cached.
      #
      def list_geo_locations(namespace)
        url = build_url(namespace)
        response = rest_get(url)
        JSON.parse(response)['resourceTypes'].first['locations']
      end

      cache_method(:list_geo_locations, cache_time)

      # Returns an array of supported api-versions for the given +namespace+ provider.
      # The results of this method are cached.
      #
      def list_api_versions(namespace)
        url = build_url(namespace)
        response = rest_get(url)
        JSON.parse(response)['resourceTypes'].first['apiVersions']
      end

      cache_method(:list_api_versions, cache_time)

      # Register the current subscription with the +namespace+ provider.
      #
      def register(namespace)
        url = build_url(namespace, 'register')
        rest_post(url)
        nil
      end

      # Unregister the current subscription from the +namespace+ provider.
      #
      def unregister(namespace)
        url = build_url(namespace, 'unregister')
        rest_post(url)
        nil
      end

      private

      def build_url(namespace = nil, *args)
        id = armrest_configuration.subscription_id
        url = File.join(Azure::Armrest::COMMON_URI, id, 'providers')
        url = File.join(url, namespace) if namespace
        url = File.join(url, *args) unless args.empty?
        url << "?api-version=#{@api_version}"
      end

    end # ResourceGroupService
  end # Armrest
end # Azure
