defmodule KindleClippingsParser.ClippingTest do
  use ExUnit.Case
  alias KindleClippingsParser.Clipping

  test "from_text" do
    text = ~S"""
    Foobar
    - Highlight Loc. 125-26 | Added on Monday, March 09, 1970, 08:35 PM

    The most generic of all books.
    So good.
    """

    clipping = Clipping.from_text(text)
    assert clipping.book_name == "Foobar"
    assert clipping.highlight_range == "125-26"
    assert clipping.time_added == "Monday, March 09, 1970, 08:35 PM"
    assert clipping.text == "The most generic of all books.\nSo good."
  end

  test "get_highlight_range_and_time_added" do
    line = "- Highlight Loc. 2949 | Added on Wednesday, December 30, 1970, 12:58 AM"
    {highlight_range, time_added} = Clipping.get_highlight_range_and_time_added(line)
    assert highlight_range == "2949"
  end

  test "from_file" do
    file = "test/data/My Clippings.txt"
    clippings = Clipping.from_file(file)

    assert Enum.count(clippings) == 3
    assert Enum.map(clippings, fn(c) -> c.book_name end) == ["Foobar", "Test", "Foobar"]
  end
end
