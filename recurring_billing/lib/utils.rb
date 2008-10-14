# This module contains common functions that ServiceMerchant uses. 
module Utils
  #Counts nubmer of months between two dates
  #
  # 2008/1/1, 2007/12/31 => 1
  # 2008/9/10, 2009/10/20 => 13
  # ETC
  def months_between(date1, date2)
    if date1 > date2
      recent_date = date1.to_date
      past_date = date2.to_date
    else
      recent_date = date2.to_date
      past_date = date1.to_date
    end
    years_diff = recent_date.year - past_date.year
    months_diff = recent_date.month - past_date.month + ((recent_date.day >= past_date.day) ? 0 : -1)
    if months_diff < 0
      months_diff = 12 + months_diff
      years_diff -= 1
    end
    return years_diff*12 + months_diff
  end
  
  # Parses given INTERVAL string into hash.
  #
  # Sample use:
  #  "1w" => {:length => 1, :unit => :w }
  #  "0.5 m" => {:length => 0.5, :unit => :m }
  #  "10 d" => {:length => 10, :unit => :d }
  #  "3y" => {:length => 3, :unit => :y }
  #  "0.25 w" => ArgumentError
  #  "2 x" => ArgumentError
  def parse_interval(interval)
    if (interval =~ /^(\d+|0\.5)\s*(d|w|m|y)$/i)
      return $1 == '0.5' ? 0.5 : $1.to_i, $2.downcase.to_sym
    end
    raise ArgumentError, "Invalid value format for payment interval: #{interval}"
  end
  
  # Returns number of payment occurrences between END_DATE and START_DATE with INTERVAL frequency.
  #
  # INTERVAL should be given in the same format parse_interval uses. END_DATE and START_DATE should be either Date or DateTime.
  # Returned number includes initial payment.
  #
  # Sample use:
  #  [Date.today(), '1 w', Date.today()+18] => 3
  #  [DateTime.new(2008, 09, 20), '1y', DateTime.new(2009, 09, 19)] => 1
  def get_occurrences(start_date, interval, end_date)

    start_date = Date.new(start_date.year,start_date.month,start_date.mday)
    end_date = Date.new(end_date.year,end_date.month,end_date.mday)
    raise ArgumentError, "Start date (#{start_date}) should be less than or equal to end date (#{end_date})" if (start_date>end_date)

    i_length, i_unit = parse_interval(interval)

    if i_length == 0.5 && ![:m, :y].include?(i_unit)
      raise ArgumentError, "Semi- interval is not supported to this units (#{i_unit.to_s})"
    end

    new_interval =  case i_unit
                      when :d then {:length=>i_length,    :unit=>:days}
                      when :w then {:length=>i_length*7,  :unit=>:days}
                      when :m then {:length=>i_length,    :unit=>:months}
                      when :y then {:length=>i_length*12, :unit=>:months}
                    end

    if new_interval[:unit] == :days
      new_occurrences = 1 + ((end_date - start_date)/new_interval[:length]).to_i
    elsif new_interval[:unit] == :months
      new_occurrences = 1 + (months_between(end_date, start_date)/new_interval[:length]).to_i 
    end
    return new_occurrences
  end
  
  # Returns midnight of specified DateTime object (as DateTime).
  def get_midnight(datetime_x)
    DateTime.new(datetime_x.year,datetime_x.month,datetime_x.mday)
  end
  
end
