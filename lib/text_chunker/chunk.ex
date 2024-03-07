defmodule TextChunker.Chunk do
  @moduledoc """
  Defines the `Chunk` struct, representing a contiguous block of text extracted during the splitting process. It stores the text content along with its corresponding byte range within the original input text.
  """

  @type t() :: %__MODULE__{
          # Byte offset of the chunk's start within the original text
          start_byte: integer(),
          # Byte offset marking the end of the chunk
          end_byte: integer(),
          # The textual content of this chunk
          text: String.t()
        }

  defstruct [:start_byte, :end_byte, :text]
end
