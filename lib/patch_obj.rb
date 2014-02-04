require 'uri'

# Class representing one patch operation.
class PatchObj
  attr_accessor :start1, :start2
  attr_accessor :length1, :length2
  attr_accessor :diffs

  def initialize(args = {})
    # Initializes with an empty list of diffs.
    @start1 = args[:start1]
    @start2 = args[:start2]
    @length1 = args[:length1] || 0
    @length2 = args[:length2] || 0
    @diffs = args[:diffs] || []
  end

  OPERATOR_TO_CHAR = {insert: '+', delete: '-', equal: ' '}
  private_constant :OPERATOR_TO_CHAR
  
  ENCODE_REGEX = /[^0-9A-Za-z_.;!~*'(),\/?:@&=+$\#-]/
  private_constant :ENCODE_REGEX

  # Emulate GNU diff's format
  # Header: @@ -382,8 +481,9 @@
  # Indices are printed as 1-based, not 0-based.
  def to_s
    coords1 = get_coords(length1, start1)
    coords2 = get_coords(length2, start2)

    text = ['@@ -', coords1, ' +', coords2, " @@\n"].join

    # Encode the body of the patch with %xx notation.
    text += diffs.map do |op, data|
      [OPERATOR_TO_CHAR[op], URI.encode(data, ENCODE_REGEX), "\n"].join
    end.join.gsub('%20', ' ')
    
    return text
  end

  def get_coords(length, start)
    if length == 0
      start.to_s + ",0"
    elsif length == 1
      (start + 1).to_s
    else
      (start + 1).to_s + "," + length.to_s
    end
  end

  private :get_coords
end
