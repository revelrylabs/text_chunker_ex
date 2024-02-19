defmodule Chunker.TextChunker do
  @moduledoc """
  Splits text into segments using a recursive splitting method, adhering to defined
  size limits and context overlap. Tracks segment byte ranges and handles oversized
  chunks with warnings. Supports fallback for non-segmentable text.
  """
  alias Chunker.Segment
  alias Chunker.Splitters.RecursiveSplit

  require Logger

  @default_opts [
    chunk_size: 2000,
    chunk_overlap: 200,
    strategy: &RecursiveSplit.recursive_split/4
  ]
  @doc """
  Generates a list of `%Segment{}` from the input text, tailored by a custom splitting strategy and options.
  """
  @spec create_segments(binary(), list(), list()) :: [Segment.t()]
  def create_segments(text, separators, opts \\ []) do
    opts = Keyword.merge(@default_opts, opts)
    chunk_size = opts[:chunk_size]
    chunk_overlap = opts[:chunk_overlap]
    strategy = opts[:strategy]

    split_text = strategy.(text, separators, chunk_size, chunk_overlap)

    segments =
      Enum.reduce(split_text, [], fn chunk, segments ->
        if String.length(chunk) > chunk_size do
          Logger.warning("Chunk size of #{String.length(chunk)} is greater than #{chunk_size}. Skipping...")

          segments
        else
          chunk_byte_from = get_chunk_byte_start(text, chunk)
          chunk_byte_to = chunk_byte_from + byte_size(chunk)

          segment = %Segment{
            start_byte: chunk_byte_from,
            end_byte: chunk_byte_to,
            text: chunk
          }

          segments ++ [segment]
        end
      end)

    if segments != [],
      do: segments,
      else: [
        %Segment{
          start_byte: 0,
          end_byte: 1,
          text: "incompatible_file_no_segments_saved"
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
