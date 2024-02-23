defmodule Chunker.Chunk do
  @moduledoc """
  Defines the `Chunk` struct, representing a contiguous block of text extracted during the splitting process. It stores the text content along with its corresponding byte range within the original input text.
  """

@type t() :: %__MODULE__{
  start_byte: integer(),  # Byte offset of the chunk's start within the original text
  end_byte: integer(),   # Byte offset marking the end of the chunk
  text: String.t()       # The textual content of this chunk
}

  defstruct [:start_byte, :end_byte, :text]
end
