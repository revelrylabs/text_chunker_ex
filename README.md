# Chunker

Chunker is an Elixir library for text segmentation.

It efficiently handles complex text, ideal for analytical and NLP applications requiring context retention. Future updates will introduce additional text splitting techniques to cater to diverse processing needs.

## Installation

Add Chunker to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:chunker, "~> 0.1.0"}
  ]
end
```

Then, fetch your dependencies with:

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

The split method returns `Segments` of your text. These chunks include the start and end bytes of each chunk.

```elixir
%Chunker.Segment{
    id: nil,
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
chunks = RecursiveSplit.split(text)
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
iex> TextChunker.split(text)

[
  %Chunker.Segment{
    id: nil,
    start_byte: 0,
    end_byte: 44,
    text: "This is a sample text. It will be split into",
  },
  %Chunker.Segment{
    id: nil,
    start_byte: 39,
    end_byte: 84,
    text: " into properly-sized chunks using the Chunker",
  },
  %Chunker.Segment{
    id: nil,
    start_byte: 84,
    end_byte: 93,
    text: " library.",
  }
]
```

Though the library currently supports only the recursive splitting method, we are actively working to include more sophisticated text splitting strategies in the future.

## Contributing

We welcome contributions to Chunker! Here's how you can help:

1. Fork the repository.
2. Create a feature branch (`git checkout -b my-new-feature`).
3. Make your changes.
4. Commit your changes (`git commit -am 'Add some feature'`).
5. Push to the branch (`git push origin my-new-feature`).
6. Create a new Pull Request.

## Acknowledgments

Special thanks to the creators of langchain for their initial approach to recursive text splitting, which inspired this library.

## License

Chunker is released under the MIT License. See the [LICENSE](LICENSE) file for details.