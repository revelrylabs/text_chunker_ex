# TextChunker usage rules

TextChunker splits text into semantically coherent chunks, commonly for embedding and retrieval in RAG pipelines.

## Basics

- `TextChunker.split(text, opts)` returns a list of `%TextChunker.Chunk{text, start_byte, end_byte}`.
  Empty input returns `[]`.
- Invalid options raise `TextChunker.Error`.
- Defaults: `chunk_size: 2000`, `chunk_overlap: 200`, `format: :plaintext`.

## Sizing

- `chunk_size` and `chunk_overlap` are measured in **graphemes** by default, or by
  `get_chunk_size` (a 1-arity function returning an integer) if given.
- `get_chunk_size` is called many times per split, so take care with passing expensive functions.
- `chunk_size` is a hard maximum; chunks are often smaller.
- `chunk_overlap` is also a maximum and is not guaranteed: it is skipped where it
  would slice a semantic boundary. It must not be greater than `chunk_size`.

## Formats

- Set `format` to match the input so chunks break at meaningful boundaries: `:markdown` breaks
  at headings and rules, `:elixir`/`:python`/etc. break at module and function definitions.
- Call `TextChunker.supported_formats/0` for the accepted values.
- Text extracted from binary formats (`:pdf`, `:docx`, `:epub`, ...) is chunked as plain text.

## Working with chunks

- Chunk text is an exact slice of the input: `binary_part(text, start_byte, end_byte - start_byte) == chunk.text`.
  Chunks may start with `"\n## "` or similar, because separators and surrounding whitespace are kept.
- Offsets are in **bytes**.
- Chunks can be whitespace-only.

## Custom strategies

- To change how text is split, write a module with `@behaviour TextChunker.Strategy` that
  implements `split(text, opts)` returning `[%TextChunker.Chunk{}]`, and pass it as `strategy:`.
