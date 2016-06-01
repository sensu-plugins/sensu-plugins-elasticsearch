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
        if !config[:transport].nil? && config[:transport] == 'AWS'
          Elasticsearch::Client.new(
            transport_class: Elasticsearch::Transport::Transport::HTTP::AWS,
            hosts: [{
              host:               config[:host],
              port:               config[:port],
              user:               config[:user],
              password:           config[:password],
              scheme:             config[:scheme],
              request_timeout:    config[:timeout],
              region:             config[:region]
            }]
          )
        else
          Elasticsearch::Client.new hosts: [{
            host:               config[:host],
            port:               config[:port],
            user:               config[:user],
            password:           config[:password],
            scheme:             config[:scheme],
            request_timeout:    config[:timeout]
          }]
        end
      elsif config[:transport].nil? && config[:transport] == 'AWS'
        Elasticsearch::Client.new host: "#{config[:host]}:#{config[:port]}", request_timeout: config[:timeout]
      else
        Elasticsearch::Client.new transport_class: Elasticsearch::Transport::Transport::HTTP::AWS,
                                  host: "#{config[:host]}:#{config[:port]}",
                                  region: config[:region],
                                  request_timeout: config[:timeout]
      end
    end
  end
end
