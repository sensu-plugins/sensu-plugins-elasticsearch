#! /usr/bin/env ruby
#
#   handle-es-disk-low-autodelete-indices.rb
#
# DESCRIPTION:
#   This handler clears out old timestamp indices.
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
#   Finds the common index patterns, takes their total disk size, then takes out
#     the oldest indexes until the total disk usage is lower than the threshold
#     configured.
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

  option :available_percent,
         description: 'Percentage of bytes to be made available after deleting indices.',
         short: '-a PERCENTAGE_AVAILABLE',
         long: '--percentage-available PERCENTAGE_AVAILABLE',
         proc: proc(&:to_i),
         default: 20

  option :maximum_butes,
         description: 'Maximum number bytes for date based indices to use.',
         short: '-m MAXIMUM_BYTES',
         long: '--maximum-butes MAXIMUM_BYTES',
         proc: proc(&:to_i),
         default: 0

  def get_indices_to_delete(starting_date, total_bytes_to_delete, indices_with_sizes)
    total_bytes_deleted = 0
    curr_date = DateTime.now()

    indices_to_delete = []

    # We don't delete the current day, as it is most likely being used.
    while total_bytes_deleted < total_bytes_to_delete && starting_date < curr_date
      same_day_indices = indices_with_sizes.values.map { |pattern|
        pattern.select { |index|
          index['date'] == starting_date
          }
        }.flatten
      for index in same_day_indices
        if total_bytes_deleted < total_bytes_to_delete
          indices_to_delete.push(index['index'])
          total_bytes_deleted = total_bytes_deleted + index['size']
        end
      end
      starting_date = starting_date + 1
    end

    return indices_to_delete
  end

  def build_indices_with_sizes
    indices_fs_stats = client.indices.stats store: true

    index_with_sizes = indices_fs_stats['indices'].keys.each_with_object({}) do |key, hash|
      matching_index = /^(.*)-(\d\d\d\d)\.(\d\d?).(\d\d?)$/.match(key)
      if matching_index != nil
        base_pattern = matching_index[1]
        if base_pattern != nil
          if !hash.include?(base_pattern)
            hash[base_pattern] = []
          end
          index_date = DateTime.new(matching_index[2].to_i, matching_index[3].to_i, matching_index[4].to_i)
          hash[base_pattern].push({
            "size" => indices_fs_stats['indices'][key]['total']['store']['size_in_bytes'].to_i,
            "date" => index_date,
            "index" => key
          })
        end
      end
    end

    return index_with_sizes
  end

  def handle

    node_fs_stats = client.nodes.stats metric: 'fs,indices'

    nodes_being_used = node_fs_stats['nodes'].values.select { |node| node['indices']['store']['size_in_bytes'] > 0 }
    used_in_bytes = nodes_being_used.map { |node| node['fs']['data'].map { |data| data['total_in_bytes'] - data['available_in_bytes'] }.flatten }.flatten.inject{|sum,x| sum + x}
    total_in_bytes = nodes_being_used.map { |node| node['fs']['data'].map { |data| data['total_in_bytes'] }.flatten }.flatten.inject{|sum,x| sum + x}

    puts("Used in bytes:      #{used_in_bytes}")
    puts("Total in bytes:     #{total_in_bytes}")

    if config[:available_percent] >= 100 || config[:available_percent] <= 0
      critical "You can not make available percentages greater than 100 or less than 0."
    end

    if config[:maximum_butes] > 0
      target_bytes_used = config[:maximum_butes]
    else
      target_bytes_used = (total_in_bytes.to_f * ((100 - config[:available]).to_f / 100.0)).to_i
    end

    puts("Target bytes used:  #{target_bytes_used}")
    total_bytes_to_delete = used_in_bytes - target_bytes_used
    if total_bytes_to_delete <= 0
      ok "Enough space already exists"
    end

    puts("Attemping to delete at least #{total_bytes_to_delete} bytes out of #{total_in_bytes}")

    indices_with_sizes = build_indices_with_sizes

    oldest = indices_with_sizes.values.flatten.map { |index| index['date'] }.min
    indices_to_delete = get_indices_to_delete(oldest, total_bytes_to_delete, indices_with_sizes)

    puts("Indices to delete: [ #{indices_to_delete.sort.join(', ')} ]")

    client.indices.delete index: indices_to_delete

    ok "finished"
  end
end
