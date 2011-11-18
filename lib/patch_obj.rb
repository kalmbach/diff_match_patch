require 'uri'

# Class representing one patch operation.
class PatchObj
  attr_accessor :start1, :start2
  attr_accessor :length1, :length2
  attr_accessor :diffs

  def initialize
    # Initializes with an empty list of diffs.
    @start1 = nil
    @start2 = nil
    @length1 = 0
    @length2 = 0
    @diffs = []
  end

  # Emulate GNU diff's format
  # Header: @@ -382,8 +481,9 @@
  # Indices are printed as 1-based, not 0-based.
  def to_s
    if length1 == 0
      coords1 = start1.to_s + ",0"
    elsif length1 == 1
      coords1 = (start1 + 1).to_s
    else
      coords1 = (start1 + 1).to_s + "," + length1.to_s
    end

    if length2 == 0
      coords2 = start2.to_s + ",0"
    elsif length2 == 1
      coords2 = (start2 + 1).to_s
    else
      coords2 = (start2 + 1).to_s + "," + length2.to_s
    end
    
    text = '@@ -' + coords1 + ' +' + coords2 + " @@\n"

    # Encode the body of the patch with %xx notation.
    diffs.each do |op, data|
      op = case op
            when :insert; '+'
            when :delete; '-'
            when :equal ; ' '
           end
      data = data.encode('utf-8')
      text += op + URI.escape(data, /[^0-9A-Za-z_.;!~*'(),\/?:@&=+$\#-]/).gsub('%20', ' ') + "\n"
    end
    
    return text
  end
end
