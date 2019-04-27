require 'yaml'
class MetroInfopoint
  def initialize(path_to_timing_file:, path_to_lines_file: )
    if path_to_timing_file == '' || !path_to_timing_file
        path_to_timing_file = 'config/timing1.yml'
      end
    if path_to_lines_file == '' || !path_to_lines_file
        path_to_lines_file = 'config/config.yml'
    end
    @info = YAML.load_file(path_to_lines_file)
    @row_data = YAML.load_file(path_to_timing_file)['timing']
    @timing_data = []

    @row_data.each_with_index do |item,i|
      item["id"] = i+1
      @timing_data.push(item)
    end
  end

  def find_ways(from_station:, to_station:)
    ways = []
    completed_ways = []
    continue_searching = true

    # Find all starting spans of ways
    spans = @timing_data.select{|e| e['start'].to_s == from_station || e['end'].to_s == from_station }

    spans.each do |item|
      span = item
      span["head"] = item["start"].to_s == from_station ? item["end"] : item["start"]
      ways.push([span])
    end

    # Iterate through all ways and find next spans
    while continue_searching do
      continue_searching = false
      new_ways = []

      ways.each do |way|
        current_span = way.last
        next_spans = @timing_data.select{|e| (e['start'] == current_span["head"] || e['end'] == current_span["head"]) && !way.any? {|s| s["id"] == e["id"]} }

        next_spans.each do |item|
          next_span = item
          next_span["head"] = next_span["start"] == current_span["head"] ? next_span["end"] : next_span["start"]
          new_way = way.dup
          new_way.push(next_span)

          if next_span["head"].to_s == to_station
            completed_ways.push(new_way)
          elsif next_span["head"].to_s != from_station
            new_ways.push(new_way)
            continue_searching = true
          end
        end
      end
      ways = new_ways.dup
    end

    return completed_ways
  end

  def calculate_value(key, ways)
    smallest_value = nil
    ways.each do |way|
      way_value = 0
      way.each do |segment|
        way_value = way_value + segment[key]
      end
      if smallest_value == nil || smallest_value > way_value
        smallest_value = way_value
      end
    end
    return smallest_value
  end

  def calculate(from_station:, to_station:)
    { price: calculate_price(from_station: from_station, to_station: to_station),
      time: calculate_time(from_station: from_station, to_station: to_station) }
  end

  def calculate_price(from_station:, to_station:)
     ways = find_ways(from_station: from_station, to_station: to_station)
     calculate_value("price", ways)
  end

  def calculate_time(from_station:, to_station:)
    ways = find_ways(from_station: from_station, to_station: to_station)
    calculate_value("time", ways)
  end
end
