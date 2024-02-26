# Chunker: Flexible Text Chunking for Elixir

![tests](https://github.com/revelrylabs/text_chunker_ex/actions/workflows/test.yml/badge.svg)

Chunker is an Elixir library for segmenting large text documents, optimizing them for efficient embedding and storage within vector databases for use in resource augmented generation (RAG) applications. 

It prioritizes context preservation and adaptability, and is therefore ideal for analytical, NLP, and other applications where understanding the relationship between text segments is crucial.

## Key Features

- Semantic Chunking: Prioritizes chunking text into meaningful blocks based on separators relevant to the specified format (e.g., headings, paragraphs in Markdown).
- Configurable Chunking: Fine-tune the chunking process with options for, text chunk size, overlap and format.
- Metadata Tracking: Automatically generates Chunk structs containing byte range information for accurately reassembling the original text if needed.
- Extensibility: Designed to accommodate additional chunking strategies in the future.


## Installation

Add Chunker to your mix.exs:

```elixir
def deps do
  [
    {:chunker, "~> 0.1.0"}
  ]
end
```

Fetch dependencies:

```
mix deps.get
```

## Usage

Begin by aliasing Chunker:

```elixir
alias Chunker.TextChunker
```

Chunk your text using the `split` function:

```elixir
text = "Your text to be split..."

chunks = TextChunker.split(text)
```

This will chunk up your text using the default parameters - a chunk size of `1000`, chunk overlap of `200`, format of :`plaintext` and using the `RecursiveChunk` strategy.

The split method returns `Chunks` of your text. These chunks include the start and end bytes of each chunk.

```elixir
%Chunker.Chunk{
    start_byte: 0,
    end_byte: 44,
    text: "This is a sample text. It will be split into",
  }
```

### Options

If you wish to adjust these parameters, configuration can optionally be passed via a keyword list. 

  - `chunk_size` -  The approximate target chunk size, as measured per code points. This means that both `a` and `👻` count as one. Chunks will not exceed this maximum, but may sometimes be smaller. **Important note** This means that graphemes *may* be split. For example, `👩‍🚒` may be split into `👩,🚒` or not depending on the split boundary.
  - `chunk_overlap` - The contextual overlap between chunks, as measured per code point. Overlap is *not* guaranteed; again this should be treated as a maximum. The size of an individual overlap will depend on the semantics of the text being split.
  - `format` (informs separator selection). Because we are trying to preserve meaning between the chunks, the format of the text we are splitting is important. It's important to split newlines in plain text; it's important to split `###` headings in markdown.

```elixir
text = """
## Your text to be split

Let's split your text up properly!
"""
opts = [chunk_size: 10, chunk_overlap: 5, format: :markdown]
chunks = TextChunker.split(text, opts)
```

### Chunking Strategies

Currently, we only implement one strategy choice: Recursive Chunk. This was reverse-engineered from LangChain, with plans to add more methods in the future. 

#### Recursive Chunk (current default)

You can use Recursive Chunk to split text up into any chunk size you wish, with or without overlap. It is important to note that this overlap is not guaranteed - rather, if the overlap makes sense, this is the max length for that overlap. Recursive Chunk prioritizes keeping the semantics intact (as defined by the separators derived from the input format). The overlap does not occur when such an overlap would break those semantics. See below for examples.

## Examples

```elixir
alias Chunker.TextChunker

text = "This is a sample text. It will be split into properly-sized chunks using the Chunker library."
opts = [chunk_size: 50, chunk_overlap: 5, format: :plaintext, strategy: &TextChunker.split/2,]

iex> TextChunker.split(text, opts)

[
  %Chunker.Chunk{
    start_byte: 0,
    end_byte: 44,
    text: "This is a sample text. It will be split into",
  },
  %Chunker.Chunk{
    start_byte: 39,
    end_byte: 84,
    text: " into properly-sized chunks using the Chunker",
  },
  %Chunker.Chunk{
    start_byte: 84,
    end_byte: 93,
    text: " library.",
  }
]
```

## Contributing and Development

Bug reports and pull requests are welcome on GitHub at https://github.com/revelrylabs/text_chunker_ex. Check out the [contributing guidelines](CONTRIBUTING.md) for more info.

Everyone is welcome to participate in the project. We expect contributors to adhere to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).

## Acknowledgments

Special thanks to the creators of langchain for their initial approach to recursive text splitting, which inspired this library. See the [NOTICE](NOTICE) file for details.

## License

Chunker is released under the MIT License. See the [LICENSE](LICENSE) file for details.
