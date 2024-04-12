defmodule TextChunker do
  @moduledoc """
  Provides a high-level interface for text chunking, employing a configurable splitting strategy (defaults to recursive splitting).  Manages options and coordinates the process, tracking chunk metadata.

  **Key Features**

  * **Customizable Splitting:**  Allows the splitting strategy to be customized via the `:strategy` option.
  * **Size and Overlap Control:**  Provides options for `:chunk_size` and `:chunk_overlap`.
  * **Metadata Tracking:**  Generates `Chunk` structs containing byte range information.

  **Supported Options**
  * `:chunk_size` (positive integer, default: 2000) - Maximum size in code point length for each chunk.
  * `:chunk_overlap` (non-negative integer, default: 200) - Number of overlapping code points between consecutive chunks to preserve context.
  * `:strategy` (module default: `RecursiveChunk`) - A module implementing the split function. Currently only `RecursiveChunk` is supported.
  * `:format` (atom, default: `:plaintext`) - The format of the input text. Used to determine where to split the text in some strategies.
  """
  alias TextChunker.Strategies.RecursiveChunk

  @supported_strategies [RecursiveChunk]

  @supported_formats [
    :doc,
    :docx,
    :epub,
    :latex,
    :odt,
    :pdf,
    :rtf,
    :markdown,
    :plaintext,
    :elixir,
    :ruby,
    :php,
    :python,
    :vue,
    :javascript,
    :typescript
  ]

  @opts_schema [
    strategy: [required: true, type: {:in, @supported_strategies}],
    chunk_overlap: [required: true, type: :non_neg_integer],
    chunk_size: [required: true, type: :pos_integer],
    format: [
      required: true,
      type: {:in, @supported_formats}
    ]
  ]

  @default_opts [
    chunk_size: 2000,
    chunk_overlap: 200,
    strategy: RecursiveChunk,
    format: :plaintext
  ]

  @doc """
  Splits the provided text into a list of `%Chunk{}` structs.

  ## Examples

  ```elixir
  iex> long_text = "This is a very long text that needs to be split into smaller pieces for easier handling."
  iex> TextChunker.split(long_text)
  # => [%Chunk{}, %Chunk{}, ...]
  ```

  iex> TextChunker.split(long_text, chunk_size: 10, chunk_overlap: 3)
  # => Generates many smaller chunks with significant overlap

  """
  @spec split(binary(), keyword()) :: [Chunk.t()] | {:error, String.t()}
  def split(text, opts \\ []) do
    opts = Keyword.merge(@default_opts, opts)

    case NimbleOptions.validate(opts, @opts_schema) do
      {:ok, args} ->
        opts[:strategy].split(text, args)

      {:error, %NimbleOptions.ValidationError{message: message}} ->
        {:error, message}
    end
  end
end
