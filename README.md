# Chunker: Flexible Text Chunking for Elixir

Chunker is an Elixir library designed to segment text effectively, prioritizing context preservation and adaptability. It's ideal for analytical, NLP, and other applications where understanding the relationship between text segments is crucial.

## Key Features

- Semantic Splitting: Prioritizes splitting text into meaningful blocks based on separators relevant to the specified format (e.g., headings, paragraphs in Markdown).
- Configurable Chunking: Fine-tune the splitting process with options for:
  - `chunk_size` (approximate target chunk size, a maximum)
  - `chunk_overlap` (contextual overlap between chunks)
  - `format` (informs separator selection)
- Metadata Tracking: Automatically generates Chunk structs containing byte range information for accurately reassembling the original text if needed.
- Extensibility: Designed to accommodate additional splitting strategies in the future.


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

Split your text using the `split` function:

```elixir
text = "Your text to be split..."

chunks = TextChunker.split(text)
```

This will split your text using the default parameters - a chunk size of `1000`, chunk overlap of `200`, format of :`plaintext` and using the `RecursiveSplit` strategy.

The split method returns `Chunks` of your text. These chunks include the start and end bytes of each chunk.

```elixir
%Chunker.Chunk{
    start_byte: 0,
    end_byte: 44,
    text: "This is a sample text. It will be split into",
  }
```

### Configuration

If you wish to adjust these parameters, configuration can optionally be passed via a keyword list. Adjustable parameters include `:chunk_size`, `:chunk_overlap`,`:format` and `:strategy`:

```elixir
text = """
## Your text to be split

Let's split your text up properly!
"""
opts = [chunk_size: 10, chunk_overlap: 5, format: :markdown]
chunks = RecursiveSplit.split(text, opts)
```

### Splitting Strategies

Currently, we only implement one strategy choice: Recursive Split. This was reverse-engineered from LangChain, with plans to add more methods in the future. 

#### Recursive Split (current default)

You can use Recursive Split to split text up into any chunk size you wish, with or without overlap. It is important to note that this overlap is not guaranteed - rather, if the overlap makes sense, this is the max length for that overlap. Recursive Split prioritizes keeping the semantics intact (as defined by the separators derived from the input format). The overlap does not occur when such an overlap would break those semantics. See below for examples.

## Examples

```elixir
alias Chunker.TextChunker

text = "This is a sample text. It will be split into properly-sized chunks using the Chunker library."
opts = [chunk_size: 50, chunk_overlap: 5, format: :plaintext, strategy: &RecursiveSplit.split/2,]

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

## Contributing

We welcome contributions to Chunker! Here's how you can help:

1. Fork the repository.
2. Create a feature branch (`git checkout -b my-new-feature`).
3. Make your changes.
4. Commit your changes (`git commit -am 'Add some feature'`).
5. Push to the branch (`git push origin my-new-feature`).
6. Create a new Pull Request.

## Acknowledgments

Special thanks to the creators of langchain for their initial approach to recursive text splitting, which inspired this library. See the [NOTICE](NOTICE) file for details.

## License

Chunker is released under the MIT License. See the [LICENSE](LICENSE) file for details.