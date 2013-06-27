require 'set'


class CheckersPiece

  SYMBOLS = { :white => ["w","W"], :black => ["b" , "B"] }

  attr_accessor :position

  def initialize(position, color, board)
    @position, @color, @board = position, color, board
    @king = false
  end

  def king?
    @king
  end

  def to_s
    king? ? SYMBOLS[@color][0], SYMBOLS[@color][1]
  end

end

class CheckersBoard
  def initialize
    spawn_pieces
  end

  def [](position)
    @pieces.select { |piece| piece.position }
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
    (0..7).map do |row|
      (0..7).map do |column|
        self[row, column]
      end
    end
  end

end

class CheckersGame

end

class CheckersPlayer

end