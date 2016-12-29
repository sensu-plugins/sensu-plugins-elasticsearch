#
# DESCRIPTION:
#   Common search helper methods
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

module ElasticsearchQuery
  def initialize
    super()
  end

  def indices(end_time)
    if !config[:index].nil?
      return config[:index]
    elsif !config[:date_index].nil?
      indices = []

      curr = end_time.to_i
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
      total = 60 * 60 * 24
      if config[:date_repeat_hourly]
        total = 60 * 60
      end
      (start.to_i..curr.to_i).step(total) do |step|
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
    end_time = (Time.now.utc - config[:offset])
    options = {

      index: indices(end_time),
      ignore_unavailable: true
    }

    unless config[:ignore_unavailable].nil?
      options[:ignore_unavailable] = config[:ignore_unavailable]
    end

    unless config[:id].nil?
      options[:id] = config[:id]
    end

    if !config[:body].nil?
      options[:body] = config[:body]
    else
      es_date_start = es_date_math_string end_time
      unless es_date_start.nil?
        options[:body] = {
          'query' => {
            'bool' => {
              'must' => [{
                'query_string' => {
                  'default_field' => config[:search_field],
                  'query' => config[:query]
                }
              }, {
                'range' => {
                  config[:timestamp_field] => {
                    'gt' => es_date_start,
                    'lt' => end_time.strftime('%Y-%m-%dT%H:%M:%S')
                  }
                }
              }]
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

  def es_date_math_string(end_time)
    if config[:minutes_previous] == 0 && \
       config[:hours_previous] == 0 && \
       config[:days_previous] == 0 && \
       config[:weeks_previous] == 0 && \
       config[:months_previous] == 0
      return nil
    else
      es_math = "#{end_time.strftime '%Y-%m-%dT%H:%M:%S'}||"
      es_math += "-#{config[:minutes_previous]}m" if config[:minutes_previous] != 0
      es_math += "-#{config[:hours_previous]}h" if config[:hours_previous] != 0
      es_math += "-#{config[:days_previous]}d" if config[:days_previous] != 0
      es_math += "-#{config[:weeks_previous]}w" if config[:weeks_previous] != 0
      es_math += "-#{config[:months_previous]}M" if config[:months_previous] != 0
      return es_math
    end
  end
end
