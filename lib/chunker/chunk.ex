defmodule Chunker.Chunk do
  @moduledoc """
  Defines the `Chunk` struct, representing a contiguous block of text along with its byte range indicators.
  """

  @type t() :: %__MODULE__{
          start_byte: integer(),
          end_byte: integer(),
          text: String.t()
        }

  defstruct [:start_byte, :end_byte, :text]
end
