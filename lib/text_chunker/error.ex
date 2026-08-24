defmodule TextChunker.Error do
  @moduledoc """
  Raised by `TextChunker.split/2` when called with invalid options.
  """
  defexception [:message]
end
