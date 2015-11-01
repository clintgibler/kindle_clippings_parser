defmodule Mix.Tasks.KindleClippingsParser.Parse do
  use Mix.Task
  alias KindleClippingsParser.Clipping

  @module_doc """
  Usage:
    $ mix kindleClippingsParser.parse --titles <path to clippings file>

    or

    $ mix kindleClippingsParser.parse <path to clippings file> <book title substring> <output file>

  """

  @shortdoc "Parse a Kindle clippings file and output structured data"
  def run(args) do
    case parse_args(args) do
      {:titles, args} -> print_titles(args)
      :help -> help
      {:export_book, clippings_file, book_title_substring, output_file} ->
        export_book_notes(clippings_file, book_title_substring, output_file)
    end
  end

  def help do
    IO.puts @module_doc
  end

  def parse_args(args) do
    default_opts = %{ :help => false, :titles => false }
    cmd_opts = OptionParser.parse(args,
                                  switches: [help: :boolean, titles: :boolean],
                                  aliases: [h: :help])

    case cmd_opts do
      { [help: true], _, _} -> :help
      { [titles: true], args, _} -> {:titles, args}
      { _, [clippings_file, book_title_substring, output_file], _} ->
        {:export_book, clippings_file, book_title_substring, output_file}
      _ -> :help
    end
  end

  def print_titles(args) do
    [clippings_file | _] = args
    clippings = Clipping.from_file(clippings_file)
    titles = clippings
    |> Enum.map(fn(c) -> c.book_name end)
    |> Enum.uniq
    |> Enum.sort

    IO.puts Enum.join(titles, "\n")
  end

  def export_book_notes(clippings_file, book_title_substring, output_file) do
    clippings = Clipping.from_file(clippings_file)
    |> Enum.filter(fn(c) -> String.contains?(c.book_name, book_title_substring) end)

    if Enum.count(clippings) == 0 do
      IO.puts "[!] No books with title matching substring '#{book_title_substring}' in '#{output_file}'"
    else
      IO.puts "[*] Writing #{Enum.count(clippings)} higlighted sections to '#{output_file}'"
      book_name = List.first(clippings).book_name
      output_str = book_name <> "\n\n"
      all_text = Enum.map(clippings, fn(c) -> wordwrap_at_num_chars(c.text, 80) end)
      |> Enum.join("\n")

      output_str = output_str <> all_text

      File.write!(output_file, output_str)
    end
  end

  # external api
  def wordwrap_at_num_chars(str, num_chars \\ 80) do
    _wordwrap_at_num_chars(String.split(str, " "), "", "", num_chars)
  end

  # if it's the first word on a line
  def _wordwrap_at_num_chars([cur_word | words], "", text, num_chars) do
    _wordwrap_at_num_chars(words, cur_word, text, num_chars)
  end

  # Handles most cases
  def _wordwrap_at_num_chars([cur_word | words], cur_line, text, num_chars) do
    if String.length(cur_line) + String.length(cur_word) <= num_chars do
      _wordwrap_at_num_chars(words, cur_line <> " " <> cur_word, text, num_chars)
    else
      _wordwrap_at_num_chars(words, cur_word, text <> "\n" <> cur_line, num_chars)
    end
  end

  # We've iterated through all words, return what's been accumulated
  def _wordwrap_at_num_chars([], cur_line, text, num_chars) do
    text <> "\n" <> cur_line
  end
end
