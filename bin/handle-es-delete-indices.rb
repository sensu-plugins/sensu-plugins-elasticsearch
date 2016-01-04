#! /usr/bin/env ruby
#
#   handle-es-delete-indices.rb
#
# DESCRIPTION:
#   This handler deletes indices.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: elasticsearch
#   gem: aws_es_transport
#
# USAGE:
#   Deletes the indices given to it from a check output and a configured
#     regex, and then deletes the indices matched.
#
# NOTES:
#
# LICENSE:
#   Brendan Leon Gibat <brendan.gibat@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-handler'
require 'elasticsearch'
require 'aws_es_transport'
require 'sensu-plugins-elasticsearch'

class ESIndexCleanup < Sensu::Handler
  include ElasticsearchCommon

  option :transport,
         long: '--transport TRANSPORT',
         description: 'Transport to use to communicate with ES. Use "AWS" for signed AWS transports.'

  option :region,
         long: '--region REGION',
         description: 'Region (necessary for AWS Transport)'

  option :host,
         description: 'Elasticsearch host',
         short: '-h HOST',
         long: '--host HOST',
         default: 'localhost'

  option :port,
         description: 'Elasticsearch port',
         short: '-p PORT',
         long: '--port PORT',
         proc: proc(&:to_i),
         default: 9200

  option :scheme,
         description: 'Elasticsearch connection scheme, defaults to https for authenticated connections',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: 'https'

  option :password,
         description: 'Elasticsearch connection password',
         short: '-P PASSWORD',
         long: '--password PASSWORD'

  option :user,
         description: 'Elasticsearch connection user',
         short: '-u USER',
         long: '--user USER'

  option :timeout,
         description: 'Elasticsearch query timeout in seconds',
         short: '-t TIMEOUT',
         long: '--timeout TIMEOUT',
         proc: proc(&:to_i),
         default: 60

  option :event_regex,
         description: 'Elasticsearch connection user',
         short: '-e EVENT_REGEX',
         long: '--event-regex EVENT_REGEX',
         default: 'INDEX\[([^\]]+)\]'

  def handle

    event_regex = Regexp.new(config[:event_regex])
    matching_indices = @event['check']['output'].scan(event_regex).flatten
    if matching_indices != nil && matching_indices.size > 0
      indices_to_delete = matching_indices[:indices].split(", ")

      puts("Deleting indices: [ #{indices_to_delete.sort.join(', ')} ]")
      client.indices.delete index: indices_to_delete
    else
      puts("No indices matched pattern to delete.")
    end
  end
end
