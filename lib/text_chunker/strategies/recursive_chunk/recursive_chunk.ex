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
                chunk_overlap
              )

            # Check if chunk exceeds size limit - if so, force character-level splitting
            if get_chunk_size.(chunk.text) > chunk_size do
              character_chunks = create_character_chunks(chunk, chunk_size, chunk_overlap)
              {final_chunks ++ character_chunks, []}
            else
              {final_chunks ++ [chunk], []}
            end

          true ->
            final_chunks =
              merge_good_splits_into_final_chunks(
                good_splits,
                final_chunks,
                chunk_size,
                chunk_overlap
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
        chunk_overlap
      )

    final_chunks
  end

  ### **Chunk Assembly:**
  defp merge_good_splits_into_final_chunks(good_splits, final_chunks, chunk_size, chunk_overlap, separator \\ "") do
    case good_splits do
      [] -> final_chunks
      _ -> final_chunks ++ merge_splits_with_positions(good_splits, chunk_size, chunk_overlap, separator)
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
  defp merge_splits_with_positions(chunk_splits, chunk_size, chunk_overlap, current_separator) do
    {final_chunks, current_splits, _splits_total_length} =
      Enum.reduce(chunk_splits, {[], [], 0}, fn split_chunk, {final_chunks, current_splits, splits_total_length} ->
        split_length = String.length(split_chunk.text)

        bigger_than_chunk? =
          splits_bigger_than_chunk?(
            split_length,
            Enum.map(current_splits, fn chunk -> chunk.text end),
            splits_total_length,
            current_separator,
            chunk_size
          )

        if bigger_than_chunk? and !Enum.empty?(current_splits) do
          # Create chunk from current_splits
          chunk_text = join_splits(Enum.map(current_splits, fn chunk -> chunk.text end), current_separator)

          chunk_start_pos =
            case current_splits do
              [first_chunk | _] -> first_chunk.start_byte
              [] -> split_chunk.start_byte
            end

          # Calculate overlap for next chunk
          {splits_total_length, current_splits} =
            reduce_chunk_size_with_positions(
              splits_total_length,
              chunk_overlap,
              chunk_size,
              split_length,
              current_splits
            )

          final_chunk = %Chunk{
            start_byte: chunk_start_pos,
            end_byte: chunk_start_pos + byte_size(chunk_text),
            text: chunk_text
          }

          new_current_splits = current_splits ++ [split_chunk]
          new_total_length = splits_total_length + split_length

          {final_chunks ++ [final_chunk], new_current_splits, new_total_length}
        else
          {final_chunks, current_splits ++ [split_chunk], splits_total_length + split_length}
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

  # Position-aware version of reduce_chunk_size that handles overlap calculation
  # Recursively reduces the chunk size while preserving position information
  defp reduce_chunk_size_with_positions(splits_total_length, chunk_overlap, chunk_size, split_length, current_splits)
       when splits_total_length > chunk_overlap or
              (splits_total_length + split_length > chunk_size and splits_total_length > 0) do
    [first_chunk | rest] = current_splits
    new_total = splits_total_length - String.length(first_chunk.text)
    reduce_chunk_size_with_positions(new_total, chunk_overlap, chunk_size, split_length, rest)
  end

  # Base case - stops reducing when overlap is achieved
  defp reduce_chunk_size_with_positions(splits_total_length, _chunk_overlap, _chunk_size, _split_length, current_splits) do
    {splits_total_length, current_splits}
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

  defp create_character_chunks(%Chunk{text: text, start_byte: start_byte}, chunk_size, chunk_overlap) do
    text_length = String.length(text)

    if text_length <= chunk_size do
      [%Chunk{text: text, start_byte: start_byte, end_byte: start_byte + byte_size(text)}]
    else
      fallback_splitter(text, start_byte, chunk_size, chunk_overlap, [])
    end
  end

  defp fallback_splitter("", _start_byte, _chunk_size, _chunk_overlap, acc), do: Enum.reverse(acc)

  defp fallback_splitter(text, start_byte, chunk_size, chunk_overlap, acc) do
    chunk_text = String.slice(text, 0, chunk_size)

    chunk = %Chunk{
      text: chunk_text,
      start_byte: start_byte,
      end_byte: start_byte + byte_size(chunk_text)
    }

    next_start = max(chunk_size - chunk_overlap, 1)
    remaining_text = String.slice(text, next_start..-1)
    next_byte_offset = start_byte + byte_size(String.slice(text, 0, next_start))

    fallback_splitter(remaining_text, next_byte_offset, chunk_size, chunk_overlap, [chunk | acc])
  end
end
