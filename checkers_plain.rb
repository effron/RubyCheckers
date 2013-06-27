# encoding: UTF-8
require 'set'
require 'colorize'


class CheckersPiece
  SYMBOLS = { :white => ["♙","♔"], :black => ["♟" , "♚"] }

  attr_accessor :position
  attr_reader :color, :board

  def initialize(position, color, board, king = false)
    @position, @color, @board = position, color, board
    @king = king
  end

  def king?
    @king
  end

  def to_s
    king? ? SYMBOLS[@color][1] : SYMBOLS[@color][0]
  end

  def perform_moves(move_sequence)
    unless @board.valid_move_seq?(move_sequence)
      raise InvalidMoveError.new, "Illegal move sequence"
    end

    perform_moves!(move_sequence)
  end

  def perform_moves!(move_sequence)
    validate_move_sequence(move_sequence)
    turn_over, just_jumped = false, false

    move_sequence[1..-1].each do |move|
      raise InvalidMoveError.new, "Can't move twice" if turn_over
      if just_jumped && slide?(move)
        raise InvalidMoveError.new, "Can't jump then slide"
      end

      perform_move(move)

      turn_over = true if slide?(move)
      just_jumped = true if jump?(move)

      promote if should_promote?
    end
  end

  private

  def promote
    @king = true
  end

  def should_promote?
    @position[0] == king_row
  end

  def king_row
    @color == :white ? 7 : 0
  end

  def direction
    @color == :white ? 1 : -1
  end

  def perform_move(move)
    if slide?(move)
      perform_slide(move)
    elsif jump?(move)
      perform_jump(move)
    else
      raise InvalidMoveError.new, "That move is neither a slide nor a jump"
    end
  end

  def slide?(move)
    y1, x1 = @position
    y2, x2 = move
    (y2 - y1).abs == 1 && (x2 - x1).abs == 1
  end

  def jump?(move)
    y1, x1 = @position
    y2, x2 = move
    (y2 - y1).abs == 2 && (x2 - x1).abs == 2
  end

  def validate_move_sequence(move_sequence)
    if move_sequence[0] != @position
      raise InvalidMoveError.new, "Illegal start position"
    end

    if move_sequence.length < 2
      raise InvalidMoveError.new, "Need a start and end location"
    end
  end

  def perform_slide(pos)
    unless slide_moves.include?(pos)
      raise InvalidMoveError.new, "Can't slide there"
    end

    @position = pos
  end

  def perform_jump(pos)
    unless jump_moves.include?(pos)
      raise InvalidMoveError.new, "Can't jump there"
    end
    y1, x1 = @position
    y2, x2 = pos
    kill_pos = [ (y1 + y2) / 2, (x1 + x2) / 2]

    @board.kill(@board[kill_pos])
    @position = pos
  end

  def slide_moves
    y, x = @position
    slides = avail_slide_pos

    slides.select do |slide|
      @board[slide].nil? && @board.on_board?(slide)
    end
  end

  def jump_moves
    avail_jump_pos.select do |pos|
      mid = @board[calc_mid_point(pos)]
      mid && mid.color != @color && @board[pos].nil?
    end
  end

  def calc_mid_point(jump_move)
    y1, x1 = @position
    y2, x2 = jump_move
    [(y1 + y2) / 2, (x1 + x2) / 2]
  end

  def avail_jump_pos
    y, x = @position
    moves = [[y + direction * 2, x + 2], [y + direction * 2, x - 2]]

    if king?
      moves += [[y - direction * 2, x + 2], [y - direction * 2, x - 2]]
    end

    moves
  end

  def avail_slide_pos
    y, x = @position
    moves = [[y + direction, x + 1], [y + direction, x - 1]]

    if king?
     moves += [[y - direction, x + 1], [y - direction, x - 1]]
    end

    moves
  end
end

class CheckersBoard

  attr_accessor :pieces

  def initialize(spawn = true)
    spawn_pieces if spawn
  end

  def [](position)
    @pieces.find { |piece| piece.position == position }
  end

  def game_over?
    [:white, :black].any? do |color|
      @pieces.select{ |piece| piece.color == color } == []
    end
  end

  def display_board
    display = build_colorized_board_array

    puts ("a".."h").inject("   "){|sum, letter| sum + " #{letter} "}
    display.each_with_index do |row, i|
      puts " #{i+1} #{row.join}"
    end

    nil
  end

  def kill(piece)
    @pieces.delete(piece)
  end

  def on_board?(position)
    position.all? { |coord| coord.between?(0,7) }
  end

  def dup
    dup_board = CheckersBoard.new(spawn = false)
    dup_board.pieces = Set.new
    @pieces.each do |piece|
      dup_board.pieces << CheckersPiece.new(piece.position, piece.color,
                                            dup_board, king = piece.king?)
    end

    dup_board
  end

  def valid_move_seq?(move_sequence)
    temp_board = self.dup
    begin
      temp_board[move_sequence[0]].perform_moves!(move_sequence)
    rescue InvalidMoveError => e
      puts e.message
      false
    else
      true
    end
  end

  private

  def build_colorized_board_array
    colors = [:red, :white]
    (0..7).map do |row|
      (0..7).map do |column|
        color = colors[(column + row) % 2]
        piece_there = self[[row, column]]
        if piece_there
          " #{piece_there.to_s} ".colorize(:background => color)
        else
          "   ".colorize(:background => color)
        end
      end
    end
  end

  def spawn_pieces
    @pieces = Set.new

    [0, 1, 2, 5, 6, 7].each do |row|
      (0..7).each do |column|
        if (column + row) % 2 == 1 && row.between?(0, 2)
          @pieces << CheckersPiece.new([row, column], :white, self)
        end

        if (column + row) % 2 == 1 && row.between?(5, 7)
          @pieces << CheckersPiece.new([row, column], :black, self)
        end
      end
    end
  end
end

class CheckersGame
  def initialize
    @board = CheckersBoard.new
    @players = { :white => CheckersPlayer.new(:white),
                 :black => CheckersPlayer.new(:black) }
    @turn_color = :white
  end

  def play
    until @board.game_over?
      play_turn
    end

    switch_turn #switches turns again because it switches after the move
    @board.display_board #one last time to see the board
    puts "#{@turn_color.to_s.capitalize} Player Wins!"
  end

  private

  def play_turn
    begin
      @board.display_board
      puts "#{@turn_color.to_s.capitalize}'s Turn"
      move_sequence = @players[@turn_color].make_move
      validate_move_sequence(move_sequence)
      @board[move_sequence[0]].perform_moves(move_sequence)
      switch_turn
    rescue InvalidMoveError => e
      puts e.message
      retry
    end
  end

  def validate_move_sequence(move_sequence)
    unless @board[move_sequence[0]]
      raise InvalidMoveError.new "no piece there"
    end

    if @board[move_sequence[0]].color != @turn_color
      raise InvalidMoveError.new "not your piece"
    end
  end

  def switch_turn
    @turn_color = @turn_color == :white ? :black : :white
  end
end

class CheckersPlayer
  def initialize(color)
    @color = color
  end

  def make_move
    puts "Please enter your move as a series of board spaces."
    moves = gets.chomp
    parse_input(moves)
  end

  private

  def parse_input(moves)
    unless moves =~ /^[a-h][1-8],([a-h][1-8],?)+$/
      raise InvalidMoveError.new "Invalid Input"
    end

    moves = moves.split(",")
    moves.map { |move| parse_coord(move)}
  end

  def parse_coord(move)
    chars = move.split(//)
    [chars[1].to_i - 1, chars[0].ord - 97]
  end
end

class InvalidMoveError < StandardError
end

game = CheckersGame.new
game.play