defmodule Chunker.TextChunker do
  @moduledoc """
  Splits text into chunks using a recursive splitting method, adhering to defined
  size limits and context overlap. Tracks chunk byte ranges and handles oversized
  chunks with warnings. Supports fallback for non-chunkable text.
  """
  alias Chunker.Chunk
  alias Chunker.Splitters.RecursiveSplit

  require Logger

  @default_opts [
    chunk_size: 2000,
    chunk_overlap: 200,
    strategy: &RecursiveSplit.split/2,
    format: :plaintext
  ]

  @doc """
  Generates a list of `%Chunk{}` from the input text, tailored by a custom splitting strategy and options.
  """
  @spec split(binary(), keyword()) :: [Chunk.t()]
  def split(text, opts \\ []) do
    opts = Keyword.merge(@default_opts, opts)
    split_text = opts[:strategy].(text, opts)

    chunks =
      Enum.reduce(split_text, [], fn chunk, chunks ->
        if String.length(chunk) > opts[:chunk_size] do
          Logger.warning("Chunk size of #{String.length(chunk)} is greater than #{opts[:chunk_size]}. Skipping...")

          chunks
        else
          chunk_byte_from = get_chunk_byte_start(text, chunk)
          chunk_byte_to = chunk_byte_from + byte_size(chunk)

          chunk = %Chunk{
            start_byte: chunk_byte_from,
            end_byte: chunk_byte_to,
            text: chunk
          }

          chunks ++ [chunk]
        end
      end)

    if chunks != [],
      do: chunks,
      else: [
        %Chunk{
          start_byte: 0,
          end_byte: 1,
          text: "incompatible_file_no_chunks_saved"
        }
      ]
  end

  defp get_chunk_byte_start(text, chunk) do
    case String.split(text, chunk, parts: 2) do
      [left, _] -> byte_size(left)
      [_] -> nil
    end
  end
end
