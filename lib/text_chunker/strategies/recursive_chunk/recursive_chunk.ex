defmodule TextChunker.Strategies.RecursiveChunk do
  @moduledoc """
  Handles recursive text splitting, aiming to adhere to configured size and overlap requirements.
  Employs a flexible separator-based approach to break down text into manageable chunks, while generating metadata for each produced chunk.

  **Key Features:**

  * **Size-Guided Chunking:** Prioritizes splitting text into semantic blocks while respecting the maximum `chunk_size`.
  * **Context Preservation:** Maintains `chunk_overlap` to minimize information loss at chunk boundaries.
  * **Separator Handling:** Selects the most appropriate delimiter (e.g., line breaks, spaces) based on the text content.
  * **Metadata Generation:** Creates `%TextChunker.Chunk{}` structs containing the split text and its original byte range.
  * **Oversized Chunk Warnings:**  Provides feedback when chunks cannot be created due to misconfiguration or limitations of the input text.

  **Algorithm Overview**

  1. **Separator Prioritization:**  Establishes a list of potential separators (e.g., line breaks, spaces), ordered by their expected relevance to the text structure.
  2. **Recursive Splitting:**
    *  Iterates through the separator list.
    *  Attempts to split the text using the current separator.
    *  If a split is successful, recursively applies the algorithm to any resulting sub-chunks that still exceed the `chunk_size`.
  3. **Chunk Assembly:**
    *  Combines smaller text segments into chunks, aiming to get as close to the `chunk_size` as possible.
    *  Employs `chunk_overlap` to ensure smooth transitions between chunks.
  4. **Metadata Generation:**  Tracks byte ranges for each chunk for potential reassembly of the original text.
  """

  @behaviour TextChunker.ChunkerBehaviour

  alias TextChunker.Chunk
  alias TextChunker.Strategies.RecursiveChunk.Separators

  require Logger

  @impl true
  @spec split(binary(), keyword()) :: [Chunk.t()]
  @doc """
  Splits the given text into chunks using a recursive strategy. Prioritizes compliance
  with  the configured `chunk_size` as a maximum, while aiming to maintain `chunk_overlap` for
  context preservation.  Intelligently handles various separators for flexible splitting.

  ## Options

  * `:chunk_size` (integer) - Target size in bytes for each chunk.
  * `:chunk_overlap` (integer) - Number of overlapping bytes between chunks.
  * `:format` (atom) -  The format of the input text (influences separator selection).

  ## Examples

  ```elixir
  iex> long_text = "This is a very long text that needs to be split into smaller pieces for easier handling."

  iex> TextChunker.Strategies.RecursiveChunk.split(long_text, chunk_size: 15, chunk_overlap: 5)
  [
    %TextChunker.Chunk{
      start_byte: 0,
      end_byte: 47,
      text: "This is a very long text that needs to be split"
    },
    %TextChunker.Chunk{
      start_byte: 38,
      end_byte: 88,
      text: " be split into smaller pieces for easier handling."
    }
  ]
  ```
  """
  def split(text, opts) do
    # First, map each character to its position
    indexed_text =
      text
      |> String.to_charlist()
      |> Enum.with_index()
      |> Enum.map(fn {char, pos} -> {<<char::utf8>>, pos} end)

    # Get options
    separators = Separators.get_separators(opts[:format])
    chunk_size = opts[:chunk_size]
    chunk_overlap = opts[:chunk_overlap]
    get_chunk_size = opts[:get_chunk_size]

    # Now split the indexed text instead of raw text
    split_text = perform_split(indexed_text, separators, chunk_size, chunk_overlap, get_chunk_size)

    produce_metadata(text, split_text, opts)
  end

  def produce_metadata(_text, split_text, opts) do
    get_chunk_size = opts[:get_chunk_size]

    chunks =
      Enum.reduce(split_text, [], fn indexed_chunk, chunks ->
        # Convert to string for size check
        chunk = Enum.map_join(indexed_chunk, &elem(&1, 0))
        chunk_size = get_chunk_size.(chunk)

        if chunk_size > opts[:chunk_size] do
          Logger.warning("Chunk size of #{chunk_size} is greater than #{opts[:chunk_size]}. Skipping...")

          chunks
        else
          # Get first and last positions
          [{_, first_pos} | _] = indexed_chunk
          {_, last_pos} = List.last(indexed_chunk)

          chunk = %Chunk{
            start_byte: first_pos,
            # +1 because end is exclusive
            end_byte: last_pos + 1,
            text: chunk
          }

          chunks ++ [chunk]
        end
      end)

    if chunks == [] do
      [
        %Chunk{
          start_byte: 0,
          end_byte: 1,
          text: "incompatible_config_or_text_no_chunks_saved"
        }
      ]
    else
      chunks
    end
  end

  defp perform_split(text, separators, chunk_size, chunk_overlap, get_chunk_size) do
    {current_separator, remaining_separators} = get_active_separator(separators, text)
    ### **Recursive Splitting:**
    {final_chunks, good_splits} =
      current_separator
      |> split_on_separator(text)
      |> Enum.reduce({[], []}, fn chunk, {final_chunks, good_splits} ->
        cond do
          chunk_small_enough?(chunk, chunk_size, get_chunk_size) ->
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

            more_chunks = perform_split(chunk, remaining_separators, chunk_size, chunk_overlap, get_chunk_size)
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

  ### **Chunk Assembly:**
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
  defp get_active_separator(all_separators, indexed_text) do
    [active_separator | rest] = all_separators

    # Convert indexed text back to string for checking
    text = Enum.map_join(indexed_text, &elem(&1, 0))

    if String.contains?(text, active_separator) do
      {active_separator, rest}
    else
      get_active_separator(rest, indexed_text)
    end
  end

  defp chunk_small_enough?(indexed_chunk, max_chunk_size, get_chunk_size) do
    # Convert indexed chunk to string for size check
    chunk = Enum.map_join(indexed_chunk, &elem(&1, 0))
    get_chunk_size.(chunk) <= max_chunk_size
  end

  # Collapses the splits based on separators into the correct chunk_size, and adds the overlap
  defp merge_splits(splits, chunk_size, chunk_overlap, current_separator) do
    splits
    |> Enum.reduce({[], [], 0}, &accumulate_splits(&1, &2, chunk_size, chunk_overlap, current_separator))
    |> finish_splits(current_separator)
  end

  defp accumulate_splits(
         indexed_split,
         {final_splits, current_splits, total_length},
         chunk_size,
         chunk_overlap,
         separator
       ) do
    split_text = Enum.map_join(indexed_split, &elem(&1, 0))
    split_length = String.length(split_text)

    # If we have splits and they're too big, finalize current splits
    if splits_too_big?(split_length, current_splits, total_length, separator, chunk_size) and
         not Enum.empty?(current_splits) do
      final_splits_to_add = join_splits(current_splits, separator)

      {splits_total_length, current_splits} =
        reduce_chunk_size(total_length, chunk_overlap, chunk_size, split_length, current_splits)

      {final_splits ++ [final_splits_to_add], current_splits ++ [indexed_split], splits_total_length + split_length}
    else
      # Otherwise accumulate this split
      {final_splits, current_splits ++ [indexed_split], total_length + split_length}
    end
  end

  defp finish_splits({final_splits, current_splits, _total_length}, separator) do
    case join_splits(current_splits, separator) do
      nil -> final_splits
      leftover -> final_splits ++ [leftover]
    end
  end

  defp splits_too_big?(length, splits, total_length, separator, chunk_size) do
    separator_length = if Enum.empty?(splits), do: 0, else: String.length(separator)
    length + total_length + separator_length > chunk_size
  end

  # Using the given separator, joins the indexed splits together
  defp join_splits([], _separator), do: nil

  defp join_splits(splits, separator) do
    # Get the next position after the last char of first split
    next_pos =
      splits
      |> List.first()
      |> List.last()
      |> elem(1)
      |> Kernel.+(1)

    # Index the separator starting at next_pos
    separator_chars =
      separator
      |> String.to_charlist()
      |> Enum.with_index(next_pos)
      |> Enum.map(&index_char/1)

    # Intersperse separator between splits and flatten
    splits
    |> Enum.intersperse(separator_chars)
    |> List.flatten()
  end

  # Convert char and position to our indexed format
  defp index_char({char, pos}), do: {<<char::utf8>>, pos}

  # Recursively reduces the chunk size. The function operates when either
  # a) the current total length of the splits exceeds the chunk overlap - this is where we create the chunk overlap
  # b) when the sum of the combined splits's total length and the length of the current split exceeds the chunk size.
  defp reduce_chunk_size(splits_total_length, chunk_overlap, chunk_size, split_length, current_splits)
       when splits_total_length > chunk_overlap or
              (splits_total_length + split_length > chunk_size and splits_total_length > 0) do
    # Convert first split to string to get its length
    first_split = current_splits |> Enum.at(0) |> Enum.map_join(&elem(&1, 0))
    new_total = splits_total_length - String.length(first_split)
    [_head | rest] = current_splits
    reduce_chunk_size(new_total, chunk_overlap, chunk_size, split_length, rest)
  end

  # Recursive base case, only used when the function above doesn't operate - starts off the next split with the overlap from the previous split
  defp reduce_chunk_size(splits_total_length, _chunk_overlap, _chunk_size, _split_length, current_splits) do
    {splits_total_length, current_splits}
  end

  defp split_on_separator(separator, indexed_text) do
    # First get the raw text for splitting
    text = Enum.map_join(indexed_text, &elem(&1, 0))

    # Use original regex strategy to get the parts
    escaped_separator = Regex.escape(separator)
    parts = Regex.split(~r/(?=#{escaped_separator})/u, text, trim: true)

    # Keep track of our position as we split
    {chunks, _} = Enum.map_reduce(parts, 0, fn part, pos ->
      chunk_length = String.length(part)
      chunk = Enum.slice(indexed_text, pos, chunk_length)
      {chunk, pos + chunk_length}
    end)

    Enum.reject(chunks, &Enum.empty?/1)
  end
end
