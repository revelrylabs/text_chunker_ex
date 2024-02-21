defmodule Chunker.Chunk do
  @moduledoc """
  Defines the `Chunk` schema, representing a contiguous block of text along with its byte range indicators.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @type t() :: %__MODULE__{}

  schema "chunks" do
    field(:start_byte, :integer)
    field(:end_byte, :integer)
    field(:text, :string)

    timestamps()
  end

  @doc false
  def changeset(chunk, attrs) do
    chunk
    |> cast(attrs, [:text, :start_byte, :end_byte])
    |> validate_required([:text, :start_byte, :end_byte])
  end
end
