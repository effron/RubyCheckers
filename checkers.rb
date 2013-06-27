# encoding: UTF-8
require 'set'
require 'colorize'


class CheckersPiece

  SYMBOLS = { :white => ["⛀","⛁"], :black => ["⛂" , "⛃"] }

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

  def promote
    @king = true
  end

  def king_row
    @color == :white ? 7 : 0
  end

  def direction
    @color == :white ? 1 : -1
  end

  def perform_moves(move_sequence)
    unless @board.valid_move_seq?(move_sequence)
      raise InvalidMoveError.new, "Illegal move sequence"
    end

    perform_moves!(move_sequence)
  end

  def perform_moves!(move_sequence)
    turn_over = false

    validate_move_sequence(move_sequence)

    move_sequence[1..-1].each do |move|
      raise InvalidMoveError.new, "Can't move twice" if turn_over
      y1, x1 = @position
      y2, x2 = move

      if (y2 - y1).abs == 1
        perform_slide(move)
        turn_over = true
      elsif (y2 - y1).abs == 2
        perform_jump(move)
      else
        raise InvalidMoveError.new, "Illegal move in sequence"
      end
      promote if @position[0] == king_row
    end
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
    moves = []

    slides.each do |slide|
      moves << slide if @board[slide].nil? && @board.on_board?(slide)
    end

    moves
  end

  def jump_moves
    y, x = @position
    jump_overs = avail_slide_pos
    jump_tos = avail_jump_pos
    jump = []

    jump_tos.each_with_index do |pos, i|
      if @board[jump_overs[i]] && @board[jump_overs[i]].color != @color && @board[pos].nil?
        jump << pos
      end
    end
    jump
  end

  def avail_jump_pos
    y, x = @position
    if king?
      [[y + direction * 2, x + 2], [y + direction * 2, x - 2],
       [y - direction * 2, x + 2], [y - direction * 2, x - 2]]
    else
      [[y + direction * 2, x + 2], [y + direction * 2, x - 2]]
    end
  end

  def avail_slide_pos
    y, x = @position
    if king?
      [[y + direction, x + 1], [y + direction, x - 1],
       [y - direction, x + 1], [y - direction, x - 1]]
    else
      [[y + direction, x + 1], [y + direction, x - 1]]
    end
  end

end

class CheckersBoard

  attr_accessor :pieces

  def initialize
    spawn_pieces
  end

  def [](position)
    @pieces.find { |piece| piece.position == position }
  end

  def game_over?
    [:white, :black].any? do |color|
      @pieces.select{ |piece| piece.color == color } == []
    end
  end

  def spawn_pieces
    @pieces = Set.new
    white_rows = [0, 1, 2]
    white_columns = [[1, 3, 5, 7], [0, 2, 4, 6], [1, 3, 5, 7]]
    black_rows = [5, 6, 7]
    black_columns = [[0, 2, 4, 6], [1 ,3 ,5 , 7],[0 ,2 ,4 , 6]]

    white_rows.each_with_index do |row, i|
      white_columns[i].each do |column|
        @pieces << CheckersPiece.new([row, column], :white, self)
      end
    end

    black_rows.each_with_index do |row, i|
      black_columns[i].each do |column|
        @pieces << CheckersPiece.new([row, column], :black, self)
      end
    end
  end

  def display_board
    colors = [:red, :white]
    display = (0..7).map do |row|
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
    dup_board = CheckersBoard.new
    dup_board.pieces = Set.new
    @pieces.each do |piece|
      dup_board.pieces << CheckersPiece.new(piece.position, piece.color, dup_board, king = piece.king?)
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

  def promote_kings
    @pieces.each do |piece|
      piece.promote if piece.position[0] == piece.king_row
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
      begin
        @board.display_board
        move_sequence = @players[@turn_color].make_move
        raise InvalidMoveError.new "no piece there" unless @board[move_sequence[0]]
        raise InvalidMoveError.new "not your piece" if @board[move_sequence[0]].color != @turn_color
        @board[move_sequence[0]].perform_moves(move_sequence)
      rescue InvalidMoveError => e
        puts e.message
        retry
      end

      switch_turn
    end
    switch_turn
    @board.display_board
    puts "#{@turn_color.to_s.capitalize} Player WINS"
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
    puts "Please enter your move a series of board spaces, starting with the piece you want to move"
    moves = gets.chomp
    parse_input(moves)
  end

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