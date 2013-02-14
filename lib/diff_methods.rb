module DiffMethods
  FIXNUM_MAX =  2**(0.size * 8 - 2) - 1

  attr_accessor :diff_timeout

  def initialize
    # Number of seconds to map a diff before giving up (0 for infinity).
    @diff_timeout = 1
  end

  # Find the differences between two texts.  Simplifies the problem by
  # stripping any common prefix or suffix off the texts before editing.
  def diff_main(text1, text2, checklines=true, deadline=nil)
    # Set a deadline by which time the diff must be complete.
    deadline ||= diff_newDeadline

    # Check for null inputs.
    raise ArgumentError.new('Null inputs. (diff_main)') unless text1 || text2

    # Check for equality (speedup).
    return (text1.empty? ? [] : [[:equal, text1]]) if text1 == text2

    diff_main_compute_diff(text1, text2, checklines, deadline)
  end

  def diff_main_compute_diff(text1, text2, checklines, deadline)
    # Trim off common prefix and suffix (speedup).
    common_prefix, text1, text2 = diff_trimCommonPrefix(text1, text2)
    common_suffix, text1, text2 = diff_trimCommonSuffix(text1, text2)

    # Compute the diff on the middle block.
    diffs = diff_compute(text1, text2, checklines, deadline)

    # Restore the prefix and suffix.
    diffs.unshift([:equal, common_prefix]) unless common_prefix.nil?
    diffs.push([:equal, common_suffix]) unless common_suffix.nil?
    diff_cleanupMerge(diffs)

    diffs
  end

  private :diff_main_compute_diff

  # Calculate a new deadline using the @diff_timeout configuration value
  def diff_newDeadline
    Time.now + (diff_timeout.zero? ? FIXNUM_MAX : diff_timeout)
  end

  private :diff_newDeadline

  # Trim off the common prefix
  def diff_trimCommonPrefix(text1, text2)
    if (common_length = diff_commonPrefix(text1, text2)).nonzero?
      common_prefix = text1[0...common_length]
      text1 = text1[common_length..-1]
      text2 = text2[common_length..-1]
    end

    return [common_prefix, text1, text2]
  end

  private :diff_trimCommonPrefix

  # Trim off the common suffix
  def diff_trimCommonSuffix(text1, text2)
    if (common_length = diff_commonSuffix(text1, text2)).nonzero?
      common_suffix = text1[-common_length..-1]
      text1 = text1[0...-common_length]
      text2 = text2[0...-common_length]
    end

    return [common_suffix, text1, text2]
  end

  private :diff_trimCommonSuffix

  # Find the differences between two texts.  Assumes that the texts do not
  # have any common prefix or suffix.
  def diff_compute(text1, text2, checklines, deadline)
    if diffs = diff_compute_common_cases(text1, text2)
      return diffs
  
    elsif diffs = diff_compute_half_match(text1, text2, checklines, deadline)
      return diffs
  
    elsif checklines && text1.length > 100 && text2.length > 100
      diff_lineMode(text1, text2, deadline)

    else
      diff_bisect(text1, text2, deadline)
    end
  end

  def diff_compute_half_match(text1, text2, checklines, deadline)
    if hm = diff_halfMatch(text1, text2)
      # A half-match was found, sort out the return data.
      text1_a, text1_b, text2_a, text2_b, mid_common = hm

      # Send both pairs off for separate processing.
      diffs_a = diff_main(text1_a, text2_a, checklines, deadline)
      diffs_b = diff_main(text1_b, text2_b, checklines, deadline)

      # Merge the results.
      return diffs_a + [[:equal, mid_common]] + diffs_b
    end
  end

  private :diff_compute_half_match

  def diff_compute_common_cases(text1, text2)
    # Just add some text (speedup).
    return [[:insert, text2]] if text1.empty?
    
    # Just delete some text (speedup).
    return [[:delete, text1]] if text2.empty?

    short, long = [text1, text2].sort_by(&:length)

    # Shorter text is inside the longer text (speedup).
    if i = long.index(short)
      op = text1.length > text2.length ? :delete : :insert
      return [[op, long[0...i]], [:equal, short], [op, long[(i + short.length)..-1]]]

    # Single character string.
    elsif short.length == 1
      # After the previous speedup, the character can't be an equality.
      return [[:delete, text1], [:insert, text2]]
    end
  end

  private :diff_compute_common_cases
end