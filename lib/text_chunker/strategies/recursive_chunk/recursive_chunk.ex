defmodule TextChunker.Strategies.RecursiveChunk do
  @moduledoc """
  Handles recursive text splitting, aiming to adhere to configured size and overlap requirements.
  Employs a flexible separator-based approach to break down text into manageable chunks, while generating metadata for each produced chunk.

  **Key Features:**

  * **Size-Guided Chunking:** Prioritizes splitting text into semantic blocks while respecting the maximum `chunk_size`.
  * **Context Preservation:** Maintains `chunk_overlap` to minimize information loss at chunk boundaries.
  * **Separator Handling:** Selects the most appropriate delimiter (e.g., line breaks, spaces) based on the text content.
  * **Metadata Generation:** Creates `%TextChunker.Chunk{}` structs containing the split text and its original byte range.

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
  Internal recursive chunking strategy. Use `TextChunker.split/2` for public API.

  Splits text using prioritized separators, respecting `chunk_size` limits while
  maintaining `chunk_overlap` for context preservation.

  ## Options

  * `:chunk_size` (integer) - Maximum chunk size
  * `:chunk_overlap` (integer) - Overlap between chunks
  * `:format` (atom) - Text format for separator selection
  * `:get_chunk_size` (function) - Size calculation function (required)
  """
  def split(text, opts) do
    separators = Separators.get_separators(opts[:format])
    chunk_size = opts[:chunk_size]
    chunk_overlap = opts[:chunk_overlap]
    get_chunk_size = opts[:get_chunk_size]
    initial_chunk = %Chunk{text: text, start_byte: 0, end_byte: byte_size(text)}
    chunks = perform_split(initial_chunk, separators, chunk_size, chunk_overlap, get_chunk_size)

    case chunks do
      [] ->
        [
          %Chunk{
            start_byte: 0,
            end_byte: 0,
            text: "No chunks created - check text content and chunk size settings"
          }
        ]

      chunks ->
        chunks
    end
  end

  # **Recursive Splitting:**
  defp perform_split(%Chunk{} = chunk, separators, chunk_size, chunk_overlap, get_chunk_size) do
    {current_separator, remaining_separators} = get_active_separator(separators, chunk)
    splits_with_positions = get_splits_with_positions(chunk, current_separator)

    {final_chunks, good_splits} =
      Enum.reduce(splits_with_positions, {[], []}, fn chunk, {final_chunks, good_splits} ->
        cond do
          chunk_small_enough?(chunk, chunk_size, get_chunk_size) ->
            {final_chunks, good_splits ++ [chunk]}

          Enum.empty?(remaining_separators) ->
            final_chunks =
              merge_good_splits_into_final_chunks(
                good_splits,
                final_chunks,
                chunk_size,
                chunk_overlap,
                get_chunk_size
              )

            if get_chunk_size.(chunk.text) > chunk_size do
              fallback_chunks = create_fallback_chunks(chunk, chunk_size, chunk_overlap, get_chunk_size)
              {final_chunks ++ fallback_chunks, []}
            else
              {final_chunks ++ [chunk], []}
            end

          true ->
            final_chunks =
              merge_good_splits_into_final_chunks(
                good_splits,
                final_chunks,
                chunk_size,
                chunk_overlap,
                get_chunk_size
              )

            more_chunks =
              perform_split(chunk, remaining_separators, chunk_size, chunk_overlap, get_chunk_size)

            {final_chunks ++ more_chunks, []}
        end
      end)

    final_chunks =
      merge_good_splits_into_final_chunks(
        good_splits,
        final_chunks,
        chunk_size,
        chunk_overlap,
        get_chunk_size
      )

    final_chunks
  end

  ### **Chunk Assembly:**
  defp merge_good_splits_into_final_chunks(
         good_splits,
         final_chunks,
         chunk_size,
         chunk_overlap,
         get_chunk_size,
         separator \\ ""
       ) do
    case good_splits do
      [] -> final_chunks
      _ -> final_chunks ++ merge_splits_with_positions(good_splits, chunk_size, chunk_overlap, get_chunk_size, separator)
    end
  end

  # Fallback when no separators match - use space as final separator
  defp get_active_separator([], _chunk) do
    {" ", []}
  end

  # Returns the first separator found in text, removing it from the list.
  # Example: ["\n\n", "\n", " "] -> if text contains "\n\n", returns {"\n\n", ["\n", " "]}
  defp get_active_separator(all_separators, %Chunk{text: text} = chunk) do
    [active_separator | rest] = all_separators

    if String.contains?(text, active_separator) do
      {active_separator, rest}
    else
      get_active_separator(rest, chunk)
    end
  end

  defp chunk_small_enough?(%Chunk{text: text}, max_chunk_size, get_chunk_size),
    do: get_chunk_size.(text) <= max_chunk_size

  # Collapses the splits based on separators into the correct chunk_size, and adds the overlap
  defp merge_splits_with_positions(chunk_splits, chunk_size, chunk_overlap, get_chunk_size, current_separator) do
    {final_chunks, current_splits} =
      Enum.reduce(chunk_splits, {[], []}, fn split_chunk, {final_chunks, current_splits} ->
        current_texts = Enum.map(current_splits, fn chunk -> chunk.text end)

        bigger_than_chunk? =
          splits_bigger_than_chunk?(
            split_chunk.text,
            current_texts,
            current_separator,
            chunk_size,
            get_chunk_size
          )

        if bigger_than_chunk? and !Enum.empty?(current_splits) do
          # Create chunk from current_splits
          chunk_text = join_splits(current_texts, current_separator)

          chunk_start_pos =
            case current_splits do
              [first_chunk | _] -> first_chunk.start_byte
              [] -> split_chunk.start_byte
            end

          # Calculate overlap for next chunk, ensuring room for the new split
          overlap_splits =
            reduce_chunk_size_with_positions(
              current_splits,
              chunk_overlap,
              chunk_size,
              split_chunk.text,
              get_chunk_size,
              current_separator
            )

          final_chunk = %Chunk{
            start_byte: chunk_start_pos,
            end_byte: chunk_start_pos + byte_size(chunk_text),
            text: chunk_text
          }

          new_current_splits = overlap_splits ++ [split_chunk]

          {final_chunks ++ [final_chunk], new_current_splits}
        else
          {final_chunks, current_splits ++ [split_chunk]}
        end
      end)

    # Handle leftover splits
    leftover_chunk =
      case current_splits do
        [] ->
          nil

        _ ->
          chunk_text = join_splits(Enum.map(current_splits, fn chunk -> chunk.text end), current_separator)

          chunk_start_pos =
            case current_splits do
              [first_chunk | _] -> first_chunk.start_byte
              [] -> 0
            end

          %Chunk{
            start_byte: chunk_start_pos,
            end_byte: chunk_start_pos + byte_size(chunk_text),
            text: chunk_text
          }
      end

    case leftover_chunk do
      nil -> final_chunks
      chunk -> final_chunks ++ [chunk]
    end
  end

  # Checks if adding split_text to current_splits would exceed chunk_size
  defp splits_bigger_than_chunk?(split_text, current_splits_texts, separator, chunk_size, get_chunk_size) do
    merged = join_splits(current_splits_texts ++ [split_text], separator)
    get_chunk_size.(merged || "") > chunk_size
  end

  # Using the given separator, joins the strings in the array current_splits together
  defp join_splits(current_splits, separator) do
    result = Enum.join(current_splits, separator)
    if String.equivalent?(result, ""), do: nil, else: result
  end

  # Position-aware version of reduce_chunk_size that handles overlap calculation
  # Drops splits from the front until:
  # 1. remaining size <= chunk_overlap, AND
  # 2. there's room to add next_split_text without exceeding chunk_size
  defp reduce_chunk_size_with_positions([], _chunk_overlap, _chunk_size, _next_split_text, _get_chunk_size, _separator),
    do: []

  defp reduce_chunk_size_with_positions(
         current_splits,
         chunk_overlap,
         chunk_size,
         next_split_text,
         get_chunk_size,
         separator
       ) do
    current_texts = Enum.map(current_splits, fn chunk -> chunk.text end)
    merged = join_splits(current_texts, separator)
    current_size = get_chunk_size.(merged || "")

    # Check if adding the next split would exceed chunk_size
    merged_with_next = join_splits(current_texts ++ [next_split_text], separator)
    size_with_next = get_chunk_size.(merged_with_next || "")

    # Reduce if:
    # - size exceeds overlap limit, OR
    # - adding the next split would exceed chunk_size (and there's something to remove)
    if current_size > chunk_overlap or (size_with_next > chunk_size and current_size > 0) do
      [_first_chunk | rest] = current_splits
      reduce_chunk_size_with_positions(rest, chunk_overlap, chunk_size, next_split_text, get_chunk_size, separator)
    else
      current_splits
    end
  end

  defp split_on_separator(separator, %Chunk{text: text}) do
    escaped_separator = Regex.escape(separator)
    regex = Regex.compile!("(?=#{escaped_separator})", [:unicode])
    Regex.split(regex, text, trim: true)
  end

  defp get_splits_with_positions(%Chunk{} = chunk, separator) do
    splits = split_on_separator(separator, chunk)

    {chunk_splits, _} =
      Enum.reduce(splits, {[], chunk.start_byte}, fn split, {acc, current_offset} ->
        new_chunk = %Chunk{
          start_byte: current_offset,
          end_byte: current_offset + byte_size(split),
          text: split
        }

        next_offset = current_offset + byte_size(split)
        {[new_chunk | acc], next_offset}
      end)

    Enum.reverse(chunk_splits)
  end

  defp create_fallback_chunks(%Chunk{text: text, start_byte: start_byte}, chunk_size, chunk_overlap, get_chunk_size) do
    text_size = get_chunk_size.(text)

    if text_size <= chunk_size do
      [%Chunk{text: text, start_byte: start_byte, end_byte: start_byte + byte_size(text)}]
    else
      fallback_splitter(text, start_byte, chunk_size, chunk_overlap, get_chunk_size, [])
    end
  end

  defp fallback_splitter("", _start_byte, _chunk_size, _chunk_overlap, _get_chunk_size, acc), do: Enum.reverse(acc)

  defp fallback_splitter(text, start_byte, chunk_size, chunk_overlap, get_chunk_size, acc) do
    # Find how many characters fit within chunk_size using the custom sizing function
    total_chars = String.length(text)
    char_count = find_char_count_for_size(text, chunk_size, get_chunk_size)
    chunk_text = String.slice(text, 0, char_count)

    chunk = %Chunk{
      text: chunk_text,
      start_byte: start_byte,
      end_byte: start_byte + byte_size(chunk_text)
    }

    # If we took everything (or overlap would cause no progress), we're done
    if char_count >= total_chars do
      Enum.reverse([chunk | acc])
    else
      # Find how many characters to keep as overlap
      overlap_chars = find_char_count_for_size(chunk_text, chunk_overlap, get_chunk_size)
      next_start = max(char_count - overlap_chars, 1)
      remaining_text = String.slice(text, next_start..-1//1)
      next_byte_offset = start_byte + byte_size(String.slice(text, 0, next_start))

      fallback_splitter(remaining_text, next_byte_offset, chunk_size, chunk_overlap, get_chunk_size, [chunk | acc])
    end
  end

  # Find the maximum number of characters that result in size <= target_size
  # Uses binary search for efficiency
  defp find_char_count_for_size(text, target_size, get_chunk_size) do
    total_chars = String.length(text)

    cond do
      total_chars == 0 -> 0
      target_size == 0 -> 0
      true -> do_find_char_count(text, target_size, get_chunk_size, 1, total_chars)
    end
  end

  defp do_find_char_count(_text, _target_size, _get_chunk_size, low, high) when low >= high, do: low

  defp do_find_char_count(text, target_size, get_chunk_size, low, high) do
    mid = div(low + high + 1, 2)
    slice = String.slice(text, 0, mid)
    size = get_chunk_size.(slice)

    if size <= target_size do
      do_find_char_count(text, target_size, get_chunk_size, mid, high)
    else
      do_find_char_count(text, target_size, get_chunk_size, low, mid - 1)
    end
  end
end
