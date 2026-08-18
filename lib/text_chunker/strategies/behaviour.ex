defmodule TextChunker.ChunkerBehaviour do
  @moduledoc """
  The contract for text splitting strategies.

  `c:split/2` receives the text and the validated options from
  `TextChunker.split/2`, and returns a list of `TextChunker.Chunk` structs
  (empty if the text produced no chunks). Raise on failure; there is no
  error-tuple return.

  Strategies must declare `@behaviour TextChunker.ChunkerBehaviour` —
  `TextChunker.split/2` rejects modules that don't.

  ```elixir
  defmodule MyApp.SentenceChunker do
    @behaviour TextChunker.ChunkerBehaviour

    @impl true
    def split(text, opts) do
      # ...
    end
  end

  TextChunker.split(text, strategy: MyApp.SentenceChunker)
  ```
  """
  alias TextChunker.Chunk

  @callback split(text :: binary(), opts :: keyword()) :: [Chunk.t()]
end
