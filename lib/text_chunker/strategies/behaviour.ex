defmodule TextChunker.ChunkerBehaviour do
  @moduledoc """
  Defines the contract that must be implemented for all text splitting strategies.
  """
  alias TextChunker.Chunk

  @callback split(text :: binary(), opts :: [keyword()]) :: [Chunk.t()]
end
