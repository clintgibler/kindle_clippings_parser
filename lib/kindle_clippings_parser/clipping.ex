
defmodule KindleClippingsParser.Clipping do
  alias KindleClippingsParser.Clipping

  @moduledoc "A struct to contain the structured info for one clipping"

  defstruct book_name: "", highlight_range: "0-1", time_added: nil, text: ""

  @doc "The separator used to separate clippings"
  def clippings_separator, do: "=========="

  @doc ~S"""
  When passed a path to a Kindle clippings file, such as the default one
  in <your Kindle>/documents/My Clippings.txt, returns a structured, parsed
  representation for you to do what you will with it.
  """
  def from_file(file) do
    {:ok, text} = File.read(file)
    unprocessed_clippings = String.split(text, clippings_separator)

    Enum.map(unprocessed_clippings, fn(text) -> Clipping.from_text(String.strip(text)) end)
    |> Enum.filter(fn(clip) -> clip != nil end)
  end

  # Clippings files tend to end with the separator and a newline, this is to filter out
  # the last empty one
  def from_text(""), do: nil

  @doc ~S"""
  Create a Clipping struct from a raw clipping text blob.

  Note: the structure of `text` will look like:

  The Structure and Interpretation of Computer Programs                # book title
  - Highlight Loc. 10-100 | Added on Monday, March 09, 1970, 08:35 PM  # highlight_range and time_added

  Lisp is really awesome because of...                                 # text
  """
  def from_text(text) do
    [book_name, range_and_time_added_line, _newline_separator | text] = String.split(text, "\n")
    {highlight_range, time_added} = get_highlight_range_and_time_added(range_and_time_added_line)

    %Clipping{book_name: book_name, highlight_range: highlight_range,
              time_added: time_added, text: Enum.join(text, "\n") |> String.strip}
  end

  def get_highlight_range_and_time_added(line) do
    [part_matched, highlight_range, time_added] = Regex.run(
      ~r/- Highlight Loc. (?<highlight_range>\d+[-\d+]*) \| Added on (?<time_added>.+)/, line)

    {highlight_range, time_added}
  end
end
