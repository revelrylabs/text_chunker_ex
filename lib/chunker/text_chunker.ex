defmodule Chunker.TextChunker do
  @moduledoc """
  Splits text into chunks using a recursive splitting method, adhering to defined
  size limits and context overlap. Tracks chunk byte ranges and handles oversized
  chunks with warnings. Supports fallback for non-chunkable text.
  """
  alias Chunker.Splitters.RecursiveSplit

  @default_opts [
    chunk_size: 2000,
    chunk_overlap: 200,
    strategy: &RecursiveSplit.split/2,
    format: :plaintext,
    raw?: false
  ]

  @doc """
  Generates a list of `%Chunk{}` from the input text, tailored by a custom splitting strategy and options.
  """
  @spec split(binary(), keyword()) :: [Chunk.t()]
  def split(text, opts \\ []) do
    opts = Keyword.merge(@default_opts, opts)

    opts[:strategy].(text, opts)
  end
end
