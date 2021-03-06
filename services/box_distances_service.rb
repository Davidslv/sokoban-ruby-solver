# From a level with one pusher and one box, compute number of pushes to put
# the box on any position of the level

class BoxDistancesService

  def initialize(level, box_position = nil)
    @level        = level
    @rows         = level.rows
    @cols         = level.cols
    @pusher       = level.pusher

    if box_position
      @box = box_position # use this param only if many boxes in level to
                          # decide which one to use with the service
    else
      @box = initialize_box_position_from_level
    end
  end

  def run(type = :minimum_for_zone)
    heap       = []

    # Initialize all distances with infinity
    @distances = Array.new(@rows * @cols) do {
        :from_left   => Float::INFINITY,
        :from_right  => Float::INFINITY,
        :from_top    => Float::INFINITY,
        :from_bottom => Float::INFINITY
      }
    end

    # Populate heap with first moves of box
    [:from_bottom, :from_top, :from_left, :from_right].each do |direction|
      heap << {
        :box       => @box,
        :pusher    => @pusher,
        :direction => direction,
        :weight    => 0
      }
    end

    # remove pusher from level
    pusher_m_before    = @pusher[:m]
    pusher_n_before    = @pusher[:n]
    pusher_cell_before = @level.read_pos(@pusher[:m], @pusher[:n])
    @level.write_pos(@pusher[:m], @pusher[:n], 's')

    # remove box from level
    box_m_before    = @box[:m]
    box_n_before    = @box[:n]
    box_cell_before = @level.read_pos(@box[:m], @box[:n])
    @level.write_pos(@box[:m], @box[:n], 's')

    # Iterate through the heap starting with lower weights
    while heap.size > 0
      dijkstra(heap, heap.pop)
    end

    # Place box and pusher back
    @level.write_pos(pusher_m_before, pusher_n_before, pusher_cell_before)
    @level.write_pos(box_m_before, box_n_before, box_cell_before)
    @level.pusher[:m] = pusher_m_before
    @level.pusher[:n] = pusher_n_before

    case type
      when :all_for_level     then all_distances_for_level
      when :minimum_for_zone  then minimum_distances_for_zone
      when :minimum_for_level then minimum_distances_for_level
      else                         nil
    end
  end

  private

  # distances from 4 directions (every position)
  def all_distances_for_level
    @distances
  end

  # keep only useful distances for zones (only inside, no walls or outside)
  def minimum_distances_for_zone
    @distances.collect.with_index do |distance, pos|
      if !' #'.include?(@level.grid[pos])
        distance.values.min
      end
    end.compact
  end

  # keep only useful distances for levels (every position)
  def minimum_distances_for_level
    @distances.collect do |distance|
      distance.values.min
    end
  end

  def initialize_box_position_from_level
    if !valid?
      raise "Error: BoxDistancesService without 'box_position' assumes the level contains only one box"
    end

    box_index = @level.grid.index('$')
    @box       = {
      :m => box_index / @cols,
      :n => box_index % @cols
    }
  end

  def dijkstra(heap, item)
    pos          = item[:box][:m]*@cols + item[:box][:n]
    box_cell     = @level.read_pos(item[:box][:m],    item[:box][:n])
    pusher_cell  = @level.read_pos(item[:pusher][:m], item[:pusher][:n])
    direction    = item[:direction]
    weight       = item[:weight]

    if !'$*#'.include?(box_cell) && !'$*#'.include?(pusher_cell) && @distances[pos][direction] > weight
      # Place box and pusher
      old_box_cell    = @level.read_pos(item[:box][:m],    item[:box][:n])
      old_pusher_cell = @level.read_pos(item[:pusher][:m], item[:pusher][:n])
      @level.write_pos(item[:box][:m],    item[:box][:n],    '$')
      @level.write_pos(item[:pusher][:m], item[:pusher][:n], '@')
      @level.pusher[:m] = item[:pusher][:m]
      @level.pusher[:n] = item[:pusher][:n]

      # Place new pusher (place where it will be before pushing the box in the direction)
      if direction == :from_bottom
        new_pusher = { :m => item[:box][:m] + 1, :n => item[:box][:n] }
        new_box    = { :m => item[:box][:m] - 1, :n => item[:box][:n] }
      elsif direction == :from_top
        new_pusher = { :m => item[:box][:m] - 1, :n => item[:box][:n] }
        new_box    = { :m => item[:box][:m] + 1, :n => item[:box][:n] }
      elsif direction == :from_left
        new_pusher = { :m => item[:box][:m], :n => item[:box][:n] - 1 }
        new_box    = { :m => item[:box][:m], :n => item[:box][:n] + 1 }
      elsif direction == :from_right
        new_pusher = { :m => item[:box][:m], :n => item[:box][:n] + 1 }
        new_box    = { :m => item[:box][:m], :n => item[:box][:n] - 1 }
      end

      # Can the pusher push in the needed direction?
      new_pusher_level_pos = new_pusher[:m] * @cols + new_pusher[:n]
      not_box_position     = !'*$'.include?(@level.grid[new_pusher_level_pos])
      new_pusher_zone_pos  = @level.level_pos_to_zone_pos[new_pusher_level_pos]

      # test if correct pusher position
      if not_box_position && new_pusher_zone_pos && Zone.new(@level, Zone::PUSHER_ZONE).bit_1?(new_pusher_zone_pos)
        @distances[pos][direction] = weight

        [:from_bottom, :from_top, :from_left, :from_right].each do |new_direction|
          index = heap.index { |heap_item| heap_item[:weight] <= weight + 1 } # keep it sorted DESC on weight!
          heap.insert(index.to_i, { # to_i because nil should be pos 0
            :box       => new_box,
            :pusher    => item[:box],
            :direction => new_direction,
            :weight    => weight + 1
          })
        end
      end

      # remove box and pusher
      @level.write_pos(item[:box][:m],    item[:box][:n],    old_box_cell)
      @level.write_pos(item[:pusher][:m], item[:pusher][:n], old_pusher_cell)
    end
  end

  def valid?
    one_box        = @level.grid.count('$') == 1
    correct_pusher = '@+'.include?(@level.read_pos(@pusher[:m], @pusher[:n]))

    one_box && correct_pusher
  end
end
