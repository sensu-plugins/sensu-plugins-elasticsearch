#
# DESCRIPTION:
#   Common helper methods
#
# DEPENDENCIES:
#   gem: elasticsearch
#   gem: sensu-plugin
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Brendan Gibat <brendan.gibat@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#
require_relative 'elasticsearch-query.rb'

module ElasticsearchCommon
  include ElasticsearchQuery
  def initialize
    super()
  end

  def client
    @client ||= begin
      if !config[:user].nil? && !config[:pass].nil? && !config[:scheme].nil?
        Elasticsearch::Client.new hosts: [{
          host:               config[:host],
          port:               config[:port],
          user:               config[:user],
          password:           config[:password],
          scheme:             config[:scheme],
          request_timeout:    config[:timeout]
        }]
      else
        Elasticsearch::Client.new host: "#{config[:host]}:#{config[:port]}", request_timeout: config[:timeout]
      end
    end
  end
end
