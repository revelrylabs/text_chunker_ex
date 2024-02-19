defmodule TextChunkerTest do
  use ExUnit.Case

  alias Chunker.Separators
  alias Chunker.Splitters.RecursiveSplit
  alias Chunker.TextChunker

  test "splits text into chunks which have the same number of bytes as the original file" do
    {:ok, text} = File.read("test/support/fixtures/document_fixtures/hamlet.txt")
    separators = Separators.get_separators(:plaintext)

    byte_size_of_chunks =
      text
      |> RecursiveSplit.split(separators, 1000, 0)
      |> Enum.reduce(0, fn chunk, total -> byte_size(chunk) + total end)

    assert byte_size(text) == byte_size_of_chunks
  end

  test "splits text into chunks with lengths that match the original file" do
    {:ok, text} = File.read("test/support/fixtures/document_fixtures/hamlet.txt")
    separators = Separators.get_separators(:plaintext)

    [%{end_byte: last_byte_length} | _rest] =
      text
      |> TextChunker.create_segments(separators)
      |> Enum.reverse()

    assert byte_size(text) == last_byte_length
  end
end
