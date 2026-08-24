defmodule TextChunker do
  @moduledoc """
  Provides a high-level interface for text chunking, employing a configurable splitting strategy (defaults to recursive splitting).  Manages options and coordinates the process, tracking chunk metadata.

  **Key Features**

  * **Customizable Splitting:**  Allows the splitting strategy to be customized via the `:strategy` option.
  * **Size and Overlap Control:**  Provides options for `:chunk_size` and `:chunk_overlap`.
  * **Metadata Tracking:**  Generates `Chunk` structs containing byte range information.

  **Supported Options**
  * `:chunk_size` (positive integer, default: 2000) - Maximum size in token length for each chunk.
  * `:get_chunk_size` (function, default: &String.length/1) - A function that returns the number of tokens in a chunk, by default the number of graphemes.
  * `:chunk_overlap` (non-negative integer, default: 200) - Number of overlapping tokens between consecutive chunks to preserve context. Must not be greater than `:chunk_size`.
  * `:strategy` (module, default: `RecursiveChunk`) - A module declaring `@behaviour TextChunker.ChunkerBehaviour`.
  * `:format` (atom, default: `:plaintext`) - The format of the input text. Used to determine where to split the text in some strategies.

  Invalid options raise `TextChunker.Error`.
  """
  alias TextChunker.Chunk
  alias TextChunker.Error
  alias TextChunker.Strategies.RecursiveChunk

  @supported_formats [
    :doc,
    :docx,
    :elixir,
    :epub,
    :html,
    :javascript,
    :latex,
    :markdown,
    :odt,
    :pdf,
    :php,
    :plaintext,
    :python,
    :rtf,
    :ruby,
    :typescript,
    :vtt,
    :vue
  ]

  @opts_schema [
    strategy: [required: true, type: {:custom, __MODULE__, :validate_strategy, []}],
    chunk_overlap: [required: true, type: :non_neg_integer],
    chunk_size: [required: true, type: :pos_integer],
    get_chunk_size: [required: false, type: {:fun, 1}],
    format: [
      required: true,
      type: {:in, @supported_formats}
    ]
  ]

  @default_opts [
    chunk_size: 2000,
    chunk_overlap: 200,
    get_chunk_size: &String.length/1,
    strategy: RecursiveChunk,
    format: :plaintext
  ]

  @doc """
  Returns the list of supported `:format` values.
  """
  @spec supported_formats() :: [atom()]
  def supported_formats, do: @supported_formats

  @doc """
  Splits the provided text into a list of `%Chunk{}` structs.

  Raises `TextChunker.Error` if the options are invalid.

  ## Examples

  ```elixir
  iex> long_text = "This is a very long text that needs to be split into smaller pieces for easier handling."
  iex> TextChunker.split(long_text)
  # => [%Chunk{}, %Chunk{}, ...]

  iex> TextChunker.split(long_text, chunk_size: 10, chunk_overlap: 3)
  # => Generates many smaller chunks with significant overlap
  ```
  """
  @spec split(binary(), keyword()) :: [Chunk.t()]
  def split(text, opts \\ []) do
    opts = Keyword.merge(@default_opts, opts)

    case NimbleOptions.validate(opts, @opts_schema) do
      {:ok, args} ->
        validate_overlap_not_greater_than_size!(args)
        args[:strategy].split(text, args)

      {:error, %NimbleOptions.ValidationError{message: message}} ->
        raise Error, message: message
    end
  end

  @doc false
  def validate_strategy(module) when is_atom(module) do
    cond do
      not (Code.ensure_loaded?(module) and declares_chunker_behaviour?(module)) ->
        {:error, "must be a module declaring @behaviour TextChunker.ChunkerBehaviour, got: #{inspect(module)}"}

      not function_exported?(module, :split, 2) ->
        {:error, "#{inspect(module)} declares @behaviour TextChunker.ChunkerBehaviour but does not implement split/2"}

      true ->
        {:ok, module}
    end
  end

  def validate_strategy(other) do
    {:error, "must be a module declaring @behaviour TextChunker.ChunkerBehaviour, got: #{inspect(other)}"}
  end

  defp declares_chunker_behaviour?(module) do
    behaviours =
      :attributes
      |> module.module_info()
      |> Keyword.get_values(:behaviour)
      |> List.flatten()

    TextChunker.ChunkerBehaviour in behaviours
  end

  defp validate_overlap_not_greater_than_size!(args) do
    if args[:chunk_overlap] > args[:chunk_size] do
      raise Error,
        message:
          "invalid value for :chunk_overlap option: must not be greater than :chunk_size (#{args[:chunk_size]}), got: #{args[:chunk_overlap]}"
    end

    :ok
  end
end
