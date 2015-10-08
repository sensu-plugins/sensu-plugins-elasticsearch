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

module ElasticsearchCommon
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

  def get_indices
    if !config[:index].nil?
      return config[:index]
    elsif !config[:date_index].nil?
      indices = []
      curr = Time.now.utc.to_i
      start = curr

      if config[:minutes_previous] != 0
        start -= (config[:minutes_previous] * 60)
      end
      if config[:hours_previous] != 0
        start -= (config[:hours_previous] * 60 * 60)
      end
      if config[:days_previous] != 0
        start -= (config[:days_previous] * 60 * 60 * 24)
      end
      if config[:weeks_previous] != 0
        start -= (config[:weeks_previous] * 60 * 60 * 24 * 7)
      end
      if config[:months_previous] != 0
        start -= (config[:months_previous] * 60 * 60 * 24 * 7 * 31)
      end
      step = 60 * 60 * 24
      if config[:date_repeat_hourly]
        step = 60 * 60
      end
      (start.to_i..curr.to_i).step(step) do |step|
        indices.push(Time.at(step).utc.strftime config[:date_index])
      end
      unless indices.include?(Time.at(curr).utc.strftime config[:date_index])
        indices.push(Time.at(curr).utc.strftime config[:date_index])
      end
      return indices.join(',')
    end
    ['_all']
  end

  def build_request_options
    options = {
      index: get_indices,
      ignore_unavailable: true
    }
    if !config[:body].nil?
      options[:body] = config[:body]
    else
      es_date_filter = get_es_date_math_string
      unless es_date_filter.nil?
        options[:body] = {
          'query' => {
            'filtered' => {
              'query' => {
                'query_string' => {
                  'default_field' => 'message',
                  'query' => config[:query]
                }
              },
              'filter' => {
                'range' => {
                  '@timestamp' => {
                    'gt' => es_date_filter
                  }
                }
              }
            }
          }
        }
      end
    end
    unless config[:types].nil?
      options[:type] = config[:types]
    end
    options
  end

  def get_es_date_math_string
    if config[:minutes_previous] == 0 && \
       config[:hours_previous] == 0 && \
       config[:weeks_previous] == 0 && \
       config[:months_previous] == 0
      return nil
    else
      es_math = "#{Time.now.utc.strftime '%Y-%m-%dT%H:%M:%S'}||"
      if config[:minutes_previous] != 0
        es_math += "-#{config[:minutes_previous]}m"
      end
      if config[:hours_previous] != 0
        es_math += "-#{config[:hours_previous]}h"
      end
      if config[:days_previous] != 0
        es_math += "-#{config[:days_previous]}d"
      end
      if config[:weeks_previous] != 0
        es_math += "-#{config[:weeks_previous]}w"
      end
      if config[:months_previous] != 0
        es_math += "-#{config[:months_previous]}M"
      end
      return es_math
    end
  end
end
