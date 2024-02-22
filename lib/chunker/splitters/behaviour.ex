defmodule Chunker.SplitterBehaviour do
  @moduledoc """
  Defines the behavior for text splitting strategies.

  Any text splitting strategy following this behavior must implement the `split/2`
  function, which takes the text to be split, and the options in the form of a keyword list
  """
  alias Chunker.Chunk

  @callback split(text :: binary(), opts :: [keyword()]) :: [Chunk.t()]
end
