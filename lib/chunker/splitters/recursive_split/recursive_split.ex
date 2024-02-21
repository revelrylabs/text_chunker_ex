defmodule Chunker.Splitters.RecursiveSplit do
  @moduledoc """
  Handles recursion-based text splitting into chunks, adhering to configured size
  and overlap requirements. It effectively divides text using various delimiters,
  ensuring logical consistency across chunks by preserving context where needed.
  """

  @behaviour Chunker.SplitterBehaviour

  alias Chunker.Splitters.RecursiveSplit.Separators
  alias Chunker.Chunk

  require Logger

  @impl true
  @spec split(binary(), keyword()) :: [binary()]
  @doc """
  Splits the given text into chunks based on specified options, using a recursive strategy
  """
  def split(text, opts) do
    separators = Separators.get_separators(opts[:format])
    chunk_size = opts[:chunk_size]
    chunk_overlap = opts[:chunk_overlap]
    split_text = perform_split(text, separators, chunk_size, chunk_overlap)

    if opts[:raw?], do: split_text, else: produce_metadata(text, split_text, opts)
  end

  def produce_metadata(text, split_text, opts) do
    chunks = Enum.reduce(split_text, [], fn chunk, chunks ->
      if String.length(chunk) > opts[:chunk_size] do
        Logger.warning("Chunk size of #{String.length(chunk)} is greater than #{opts[:chunk_size]}. Skipping...")

        chunks
      else
        chunk_byte_from = get_chunk_byte_start(text, chunk)
        chunk_byte_to = chunk_byte_from + byte_size(chunk)

        chunk = %Chunk{
          start_byte: chunk_byte_from,
          end_byte: chunk_byte_to,
          text: chunk
        }

        chunks ++ [chunk]
      end
    end)

    if chunks != [],
    do: chunks,
    else: [
      %Chunk{
        start_byte: 0,
        end_byte: 1,
        text: "incompatible_config_or_text_no_chunks_saved"
      }
    ]
  end

  defp perform_split(text, separators, chunk_size, chunk_overlap) do
    {current_separator, remaining_separators} = get_active_separator(separators, text)

    {final_chunks, good_splits} =
      current_separator
      |> split_on_separator(text)
      |> Enum.reduce({[], []}, fn chunk, {final_chunks, good_splits} ->
        cond do
          chunk_small_enough?(chunk, chunk_size) ->
            {final_chunks, good_splits ++ [chunk]}

          Enum.empty?(remaining_separators) ->
            final_chunks =
              merge_good_splits_into_final_chunks(
                good_splits,
                final_chunks,
                chunk_size,
                chunk_overlap
              )

            {final_chunks ++ [chunk], []}

          true ->
            final_chunks =
              merge_good_splits_into_final_chunks(
                good_splits,
                final_chunks,
                chunk_size,
                chunk_overlap
              )

            more_chunks = perform_split(chunk, remaining_separators, chunk_size, chunk_overlap)
            {final_chunks ++ more_chunks, []}
        end
      end)

    final_chunks =
      merge_good_splits_into_final_chunks(
        good_splits,
        final_chunks,
        chunk_size,
        chunk_overlap
      )

    final_chunks
  end

  defp merge_good_splits_into_final_chunks(good_splits, final_chunks, chunk_size, chunk_overlap, separator \\ "") do
    case good_splits do
      [] -> final_chunks
      _ -> final_chunks ++ merge_splits(good_splits, chunk_size, chunk_overlap, separator)
    end
  end

  # Fallback to an empty string as separator. This means it's one gigantic line of nothingness
  # with no separators. It will get ignored inside TextChunker.split/2. The separator we
  # pass back is meaningless (unless it's "" in which case we will get chunks
  # but it might be very slow.)
  defp get_active_separator([], _text) do
    {" ", []}
  end

  # Gets the separator to be used on this round of iteration. For example:
  # The list ["\n\n", "\n" ," "].
  # If the text has "\n\n", then that will be the separator, and it drops that from the list
  # If the text does't have it, then it goes to "\n" and so forth
  defp get_active_separator(all_separators, text) do
    [active_separator | rest] = all_separators

    if String.contains?(text, active_separator) do
      {active_separator, rest}
    else
      get_active_separator(rest, text)
    end
  end

  defp chunk_small_enough?(chunk, max_chunk_size), do: String.length(chunk) <= max_chunk_size

  # Collapses the splits based on separators into the correct chunk_size, and adds the overlap
  defp merge_splits(splits, chunk_size, chunk_overlap, current_separator) do
    {final_splits, current_splits, _split_total_length} =
      Enum.reduce(splits, {[], [], 0}, fn split, {final_splits, current_splits, splits_total_length} ->
        split_length = String.length(split)

        bigger_than_chunk? =
          splits_bigger_than_chunk?(
            split_length,
            current_splits,
            splits_total_length,
            current_separator,
            chunk_size
          )

        if bigger_than_chunk? and !Enum.empty?(current_splits) do
          final_splits_to_add = join_splits(current_splits, current_separator)

          {splits_total_length, current_splits} =
            reduce_chunk_size(
              splits_total_length,
              chunk_overlap,
              chunk_size,
              split_length,
              current_splits
            )

          {final_splits ++ [final_splits_to_add], current_splits ++ [split], splits_total_length + split_length}
        else
          {final_splits, current_splits ++ [split], splits_total_length + split_length}
        end
      end)

    leftover_splits = join_splits(current_splits, current_separator)
    final_splits ++ [leftover_splits]
  end

  # Checks if the combined splits is bigger than the chunk
  defp splits_bigger_than_chunk?(length, current_splits, splits_total_length, separator, chunk_size) do
    additional_length = if Enum.count(current_splits) > 0, do: String.length(separator), else: 0
    length + splits_total_length + additional_length > chunk_size
  end

  # Using the given separator, joins the strings in the array current_splits together
  defp join_splits(current_splits, separator) do
    result = Enum.join(current_splits, separator)
    if String.equivalent?(result, ""), do: nil, else: result
  end

  # Recursively reduces the chunk size. The function operates when either
  # a) the current total length of the splits exceeds the chunk overlap - this is where we create the chunk overlap
  # b) when the sum of the combined splits's total length and the length of the current split exceeds the chunk size.
  defp reduce_chunk_size(splits_total_length, chunk_overlap, chunk_size, split_length, current_splits)
       when splits_total_length > chunk_overlap or
              (splits_total_length + split_length > chunk_size and splits_total_length > 0) do
    new_total = splits_total_length - String.length(Enum.at(current_splits, 0))
    [_head | rest] = current_splits
    reduce_chunk_size(new_total, chunk_overlap, chunk_size, split_length, rest)
  end

  # Recursive base case, only used when the function above doesn't operate - starts off the next split with the overlap from the previous split
  defp reduce_chunk_size(splits_total_length, _chunk_overlap, _chunk_size, _split_length, current_splits) do
    {splits_total_length, current_splits}
  end

  defp split_on_separator(separator, text) do
    escaped_separator = escape_special_chars(separator)
    Regex.split(~r/(?=#{escaped_separator})/u, text, trim: true)
  end

  defp escape_special_chars(separator) do
    Regex.replace(~r/([\/\-\\\^\$\*\+\?\.\(\)\|\[\]\{\}])/u, separator, "\\\\\\0")
  end

  defp get_chunk_byte_start(text, chunk) do
    case String.split(text, chunk, parts: 2) do
      [left, _] -> byte_size(left)
      [_] -> nil
    end
  end
end
