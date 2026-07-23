defmodule TextChunker.RecursiveChunkPropertyTest do
  @moduledoc """
  Property-based invariant tests for `TextChunker`.

  Unlike the golden-output tests in `recursive_chunk_test.exs`, these assert
  invariants that must hold for *any* input and any valid option combination,
  providing a safety net for internals refactors.
  """
  use ExUnit.Case, async: true
  use ExUnitProperties

  @formats [
    :doc,
    :docx,
    :elixir,
    :epub,
    :html,
    :javascript,
    :latex,
    :markdown,
    :odt,
    :pdf,
    :php,
    :plaintext,
    :python,
    :rtf,
    :ruby,
    :typescript,
    :vtt,
    :vue
  ]

  # Fragments that stress the chunker: unicode, emoji (including multi-codepoint
  # ZWJ sequences), CRLF pairs, whitespace runs, and format-specific separators.
  @tricky_fragments [
    " ",
    "\n",
    "\n\n",
    "\r\n",
    "\t",
    "é",
    "é",
    "中文",
    "…",
    "💻",
    "👍🏿",
    "👨‍👩‍👧‍👦",
    "\ndef ",
    "  def ",
    "\nclass ",
    "\ndefmodule ",
    "public function ",
    "<p>",
    "<template>",
    "## ",
    "```\n\n"
  ]

  defp input_text do
    fragment =
      one_of([
        string(:alphanumeric, min_length: 1),
        string(:printable, min_length: 1),
        member_of(@tricky_fragments)
      ])

    fragment
    |> list_of(min_length: 1, max_length: 30)
    |> map(&Enum.join/1)
  end

  # Like input_text/0, but without raw `string(:printable)`. Arbitrary printable
  # codepoints include Prepend-class characters (e.g. U+0600), which form a
  # single grapheme cluster with a *following* ASCII character; a separator
  # match there splits the cluster. Real-world text virtually never does this,
  # and the documented grapheme guarantee (README) excepts only CRLF, so the
  # grapheme property sticks to a curated alphabet.
  defp grapheme_safe_text do
    fragment =
      one_of([
        string(:alphanumeric, min_length: 1),
        string(Enum.concat([?a..?z, [?\s, ?\n, ?., ?!, ??, ?<, ?#, ?`]]), min_length: 1),
        member_of(@tricky_fragments)
      ])

    fragment
    |> list_of(min_length: 1, max_length: 30)
    |> map(&Enum.join/1)
  end

  defp chunk_opts do
    gen all(
          chunk_size <- integer(1..64),
          chunk_overlap <- integer(0..max(chunk_size - 1, 0)),
          format <- member_of(@formats)
        ) do
      [chunk_size: chunk_size, chunk_overlap: chunk_overlap, format: format]
    end
  end

  property "with zero overlap, concatenating all chunks reconstructs the input byte-for-byte" do
    check all(text <- input_text(), opts <- chunk_opts()) do
      chunks = TextChunker.split(text, Keyword.put(opts, :chunk_overlap, 0))

      assert Enum.map_join(chunks, & &1.text) == text

      chunks
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.each(fn [previous, current] ->
        assert current.start_byte == previous.end_byte,
               "zero-overlap chunks must be contiguous: " <>
                 "#{inspect(previous)} is followed by #{inspect(current)}"
      end)
    end
  end

  property "chunk text always equals the input bytes at start_byte..end_byte" do
    check all(text <- input_text(), opts <- chunk_opts()) do
      for chunk <- TextChunker.split(text, opts) do
        assert chunk.text ==
                 binary_part(text, chunk.start_byte, chunk.end_byte - chunk.start_byte)

        assert String.valid?(chunk.text)
      end
    end
  end

  property "no chunk exceeds chunk_size as measured by the default get_chunk_size" do
    check all(text <- input_text(), opts <- chunk_opts()) do
      for chunk <- TextChunker.split(text, opts) do
        assert String.length(chunk.text) <= opts[:chunk_size]
      end
    end
  end

  property "no chunk exceeds chunk_size as measured by a custom get_chunk_size" do
    # 1 "token" ≈ 4 characters, with a floor of 1 so any non-empty text has a size
    token_counter = fn text -> max(1, div(String.length(text), 4)) end

    check all(text <- input_text(), opts <- chunk_opts()) do
      opts = Keyword.put(opts, :get_chunk_size, token_counter)

      for chunk <- TextChunker.split(text, opts) do
        assert token_counter.(chunk.text) <= opts[:chunk_size]
      end
    end
  end

  property "start bytes are monotonically non-decreasing and chunks span the whole input" do
    check all(text <- input_text(), opts <- chunk_opts()) do
      chunks = TextChunker.split(text, opts)
      start_bytes = Enum.map(chunks, & &1.start_byte)

      assert start_bytes == Enum.sort(start_bytes)
      assert hd(chunks).start_byte == 0
      assert List.last(chunks).end_byte == byte_size(text)

      chunks
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.each(fn [previous, current] ->
        assert current.start_byte <= previous.end_byte,
               "chunks must not leave gaps: " <>
                 "#{inspect(previous)} is followed by #{inspect(current)}"
      end)
    end
  end

  property "chunk boundaries never split a grapheme, except a CRLF pair" do
    check all(text <- grapheme_safe_text(), opts <- chunk_opts()) do
      boundaries =
        text
        |> TextChunker.split(opts)
        |> Enum.flat_map(&[&1.start_byte, &1.end_byte])
        |> Enum.uniq()

      for boundary <- boundaries do
        assert grapheme_boundary?(text, boundary),
               "byte offset #{boundary} splits a grapheme of #{inspect(text)}"
      end
    end
  end

  # A byte offset is a grapheme boundary if cutting the text there leaves the
  # grapheme sequence intact. The separator splitter may divide a CRLF pair
  # (a single grapheme) - the one documented exception, see README.
  defp grapheme_boundary?(_text, 0), do: true
  defp grapheme_boundary?(text, offset) when offset == byte_size(text), do: true

  defp grapheme_boundary?(text, offset) do
    <<prefix::binary-size(offset), suffix::binary>> = text

    crlf_split? = String.ends_with?(prefix, "\r") and String.starts_with?(suffix, "\n")

    crlf_split? or
      (String.valid?(prefix) and String.valid?(suffix) and
         String.graphemes(prefix) ++ String.graphemes(suffix) == String.graphemes(text))
  end
end
