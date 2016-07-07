# Class containing a level and every methods about it
#
# Positions in grid start in the upper-left corner with (m=0,n=0).
#
# Example : (2,4) means third rows and fifth cols starting in the upper-left
# corner.
#
# Grid is made like this in loaded files :
#
#      #####                 # -> wall
#      #   #                 $ -> box
#      #$  #                 . -> goal
#    ###  $##                * -> box on a goal (not in this figure)
#    #  $ $ #                @ -> pusher
#  ### # ## #   ######       + -> pusher on a goal
#  #   # ## #####  ..#       s -> inside floor (generated by recursive
#  # $  $          ..#            algorithm)
#  ##### ### #@##  ..#
#      #     #########
#      #######

class Level

  NO_MOVE     = 0
  NORMAL_MOVE = 1
  BOX_MOVE    = 2

  attr_reader :name, :copyright, :rows, :cols, :grid, :boxes,
              :goals, :pusher, :size, :inside_size,
              :level_pos_to_zone_pos, :zone_pos_to_level_pos

  def initialize(level)
    @inside_cells = Level.inside_cells

    if level.is_a? Level
      create_level_from_level(level)
    else
      if level.is_a? Nokogiri::XML::Element
        initialize_grid_from_xml(level)
      elsif level.is_a? String
        initialize_grid_from_text(level)
      elsif level.is_a? Node
        initialize_grid_from_node(level)
      end

      initialize_pusher_position
      initialize_floor
      initialize_size
      initialize_boxes_and_goals
      initialize_level_zone_positions
    end
  end

  def read_pos(m, n)
    if m < @rows && n < @cols && m >= 0 && n >= 0
      @grid[@cols*m + n]
    else
      raise "Try to read value out of level's grid"
    end
  end

  def write_pos(m, n, letter)
    if m < @rows && n < @cols && m >= 0 && n >= 0
      @grid[@cols*m + n] = letter
    else
      raise "Try to write value out of level's grid"
    end
  end

  # Direction should be 'u', 'd', 'l', 'r' in lowercase or uppercase
  def can_move?(direction)
    m = @pusher[:pos_m]
    n = @pusher[:pos_n]

    direction = direction.downcase

    # Following of the direction, test 2 cells
    if direction == 'u'
      move1 = read_pos(m-1, n)
      move2 = read_pos(m-2, n)
    elsif direction == 'd'
      move1 = read_pos(m+1, n)
      move2 = read_pos(m+2, n)
    elsif direction == 'l'
      move1 = read_pos(m, n-1)
      move2 = read_pos(m, n-2)
    elsif direction == 'r'
      move1 = read_pos(m, n+1)
      move2 = read_pos(m, n+2)
    end

    # Check that's not a wall, or two boxes, or one boxes and a wall
    !(move1 == '#' || ((move1 == '*' || move1 == '$') && (move2 == '*' || move2 == '$' || move2 == '#')))
  end

  # Direction should be 'u', 'd', 'l', 'r' in lowercase or uppercase
  # Return NO_MOVE, NORMAL_MOVE or BOX_MOVE
  def move(direction)
    action = true
    m      = @pusher[:pos_m]
    n      = @pusher[:pos_n]

    direction = direction.downcase

    # Following of the direction, test 2 cells
    if direction == 'u' && can_move?('u')
      m_1 = m-1
      m_2 = m-2
      n_1 = n_2 = n
      @pusher[:pos_m] -= 1
    elsif direction == 'd' && can_move?('d')
      m_1 = m+1
      m_2 = m+2
      n_1 = n_2 = n
      @pusher[:pos_m] += 1
    elsif direction == 'l' && can_move?('l')
      n_1 = n-1
      n_2 = n-2
      m_1 = m_2 = m
      @pusher[:pos_n] -= 1
    elsif direction == 'r' && can_move?('r')
      n_1 = n+1
      n_2 = n+2
      m_1 = m_2 = m
      @pusher[:pos_n] += 1
    else
      action = false
      state = NO_MOVE
    end

    # Move accepted
    if action
      state = NORMAL_MOVE

      # Test on cell (m,n)
      if read_pos(m, n) == '+'
        write_pos(m, n, '.')
      else
        write_pos(m, n, 's')
      end

      # Test on cell (m_2,n_2)
      if ['$', '*'].include? read_pos(m_1, n_1)
        if read_pos(m_2, n_2) == '.'
          write_pos(m_2, n_2, '*')
        else
          write_pos(m_2, n_2, '$')
        end

        state = BOX_MOVE
      end

      # Test on cell (m_1, n_1)
      if ['.', '*'].include? read_pos(m_1, n_1)
        write_pos(m_1, n_1, '+')
      else
        write_pos(m_1, n_1, '@')
      end
    end

    state
  end

  def valid?
    criteria_1 = @boxes == @goals
    criteria_2 = @grid.count { |cell| ['@', '+'].include? cell } == 1

    criteria_1 && criteria_2
  end

  def won?
    !(@grid.any? { |cell| cell == '$' })
  end

  def print
    puts to_s
  end

  def to_s
    @grid.join.tr('s', ' ').scan(/.{#{@cols}}/).join("\n")
  end

  def to_node
    Node.new(self)
  end

  # compare on the grid only!
  def ==(other_level)
    @grid == other_level.grid
  end

  def clone
    Level.new(self)
  end

  def self.inside_cells
    ['$', '.', '*', '@', '+', 's']
  end

  private

  def initialize_grid_from_xml(xml_level_node)
    @rows          = xml_level_node.attr('Height').strip.to_i
    @cols          = xml_level_node.attr('Width').strip.to_i
    @name          = xml_level_node.attr('Id').strip
    copyright_node = xml_level_node.attr('Copyright')
    @copyright     = copyright_node ? copyright_node.strip : ""

    lines = xml_level_node.css("L").collect(&:text)
    @grid = lines.collect { |line| line.ljust @cols }.join.split('')
  end

  def initialize_grid_from_text(text_level)
    lines      = text_level.split("\n").select { |line| line.strip != '' }
    @rows      = lines.size
    @cols      = lines.max_by { |line| line.rindex('#') }.rstrip.length
    @name      = ''
    @copyright = ''
    @grid      = lines.collect { |line| line.ljust(@cols)[0..@cols-1] }.join.split('')
  end

  # Can't get exact position of pusher from a node
  # Take first eligible position of pusher from pusher_zone
  def initialize_grid_from_node(node)
    boxes_zone  = node.boxes_zone
    goals_zone  = node.goals_zone
    pusher_zone = node.pusher_zone
    level       = node.level

    @rows      = level.rows
    @cols      = level.cols
    @name      = level.name
    @copyright = level.copyright

    pos         = 0
    pusher_flag = false
    @grid = level.grid.collect do |cell|
      # Only keep empty spaces
      if ['@', '$', '*', '+'].include? cell
        new_cell = 's'
      else
        new_cell = cell
      end

      if @inside_cells.include? new_cell
        # Place goals from zone
        if goals_zone.bit_1?(pos)
          new_cell = '.'
        end

        # Place boxes from zone
        if boxes_zone.bit_1?(pos)
          new_cell = new_cell == '.' ? '*' : '$'
        # Place pusher from zone
        elsif !pusher_flag && pusher_zone.bit_1?(pos)
          new_cell = new_cell == '.' ? '+' : '@'
          pusher_flag = true
        end

        pos += 1
      end

      new_cell
    end
  end

  def create_level_from_level(level)
    @rows        = level.rows
    @cols        = level.cols
    @size        = @cols * @rows
    @inside_size = level.inside_size
    @name        = level.name
    @boxes       = level.boxes
    @goals       = level.goals
    @copyright   = level.copyright

    @grid        = level.grid.collect do |cell|
      cell
    end

    @pusher = {
      :pos_m => level.pusher[:pos_m],
      :pos_n => level.pusher[:pos_n]
    }

    # Don't need to copy, reference is ok because doesn't change
    @level_pos_to_zone_pos = level.level_pos_to_zone_pos
    @zone_pos_to_level_pos = level.zone_pos_to_level_pos
  end

  def initialize_size
    @size = @cols * @rows

    @inside_size = @grid.count do |cell|
      @inside_cells.include? cell
    end
  end

  def initialize_pusher_position
    pos = @grid.index { |cell| ['@', '+'].include? cell }
    @pusher = {
      :pos_m => (pos / @cols).floor,
      :pos_n => pos % @cols
    }
  end

  # Transform empty spaces inside level in floor represented by 's'.
  def initialize_floor
    initialize_floor_rec(@pusher[:pos_m], @pusher[:pos_n])

    # Set back symbols to regular symbols
    @grid = @grid.collect { |cell| cell.tr('pda', '.$*') }
  end

  # Recursive function used by make_floor
  def initialize_floor_rec(m, n)
    cell = read_pos(m, n)

    # Change of values to "floor" or "visited"
    new_cell = case cell
      when ' ' then 's' # floor
      when '.' then 'p' # visited goal
      when '$' then 'd' # visited box
      when '*' then 'a' # visited box on goal
      else nil
    end

    write_pos(m, n, new_cell) if new_cell

    # If non-visited cell, test neighbours cells
    if !['#', 's', 'p', 'd', 'a'].include? cell
      initialize_floor_rec(m+1, n)
      initialize_floor_rec(m-1, n)
      initialize_floor_rec(m, n+1)
      initialize_floor_rec(m, n-1)
    end
  end

  def initialize_boxes_and_goals
    @boxes = @grid.count { |cell| ['*', '$'].include? cell }
    @goals = @grid.count { |cell| ['+', '*', '.'].include? cell }
  end

  def initialize_level_zone_positions
    @level_pos_to_zone_pos = {}
    @zone_pos_to_level_pos = {}

    zone_pos = 0
    @grid.each_with_index do |cell, level_pos|
      @level_pos_to_zone_pos[level_pos] = nil

      if @inside_cells.include? cell
        @level_pos_to_zone_pos[level_pos] = zone_pos
        @zone_pos_to_level_pos[zone_pos]  = level_pos

        zone_pos += 1
      end
    end
  end
end
