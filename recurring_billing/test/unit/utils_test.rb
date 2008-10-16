require File.dirname(__FILE__) + '/../test_helper'

class UtilsTest < Test::Unit::TestCase
  def test_months_between
    def d(string);return Date.parse(string);end
    
    assert months_between(d("2008/10/01"), d("2008/10/01")), 0
    assert months_between(d("2008/10/02"), d("2008/10/01")), 0
    assert months_between(d("2008/11/01"), d("2008/10/02")), 0
    assert months_between(d("2008/01/01"), d("2007/12/31")), 0
    assert months_between(d("2008/11/01"), d("2008/10/01")), 1
    assert months_between(d("2008/02/01"), d("2007/05/01")), 9
    assert months_between(d("2008/02/14"), d("2007/05/01")), 9
    assert months_between(d("2008/02/02"), d("2007/05/13")), 8
  end

end
