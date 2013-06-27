# encoding: UTF-8
require 'set'


class CheckersPiece

  SYMBOLS = { :white => ["w","W"], :black => ["b" , "B"] }

  attr_accessor :position
  attr_reader :color

  def initialize(position, color, board)
    @position, @color, @board = position, color, board
    @king = false
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
    slides = [[y + direction, x + 1], [y + direction, x - 1]]
    moves = []
    slides.each do |slide|
      moves << slide if @board[slide].nil? && @board.on_board?(slide)
      p @board[slide]
    end

    moves
  end

  def jump_moves
    y, x = @position
    jump_overs = [[y + direction, x + 1], [y + direction, x - 1]]
    jump_tos = [[y + direction * 2, x + 2], [y + direction * 2, x - 2]]
    jump = []

    jump_tos.each_with_index do |pos, i|
      if @board[jump_overs[i]] && @board[jump_overs[i]].color == @color && @board[pos].nil?
        jump << pos
      end
    end

    jump
  end

end

class CheckersBoard
  def initialize
    spawn_pieces
  end

  def [](position)
    @pieces.find { |piece| piece.position == position }
  end

  def kill(piece)
    @pieces.delete(piece)
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
    display = (0..7).map do |row|
      (0..7).map do |column|
        piece_there = self[[row, column]]
        piece_there ? piece_there.to_s : " "
      end
    end

    display.each do |row|
      puts row.join(" | ")
      puts
    end
  end

  def on_board?(position)
    position.all? { |coord| coord.between?(0,7) }
  end
end

class CheckersGame

end

class CheckersPlayer

end

class InvalidMoveError < StandardError
end

board = CheckersBoard.new
board.display_board