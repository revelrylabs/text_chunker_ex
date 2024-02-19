# Chunker

Chunker is an Elixir library for text segmentation.

It efficiently handles complex text, ideal for analytical and NLP applications requiring context retention. Future updates will introduce additional text splitting techniques to cater to diverse processing needs. It initially features a recursive splitting method which has been reverse-engineered from LangChain, with plans to add more methods in the future. 

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

Begin by importing Chunker:

```elixir
alias Chunker.RecursiveSplit
```

Split your text using the `recursive_split` function:

```elixir
text = "Your text to be split..."
separators = ["\n\n", ". ", "? ", "! "] # Customize your separators
chunk_size = 1000  # Maximum size for each chunk
chunk_overlap = 200  # Overlapping characters for context

chunks = RecursiveSplit.recursive_split(text, separators, chunk_size, chunk_overlap)
```

### Parameters

- `text` - The text to be split into chunks.
- `separators` - A list of string delimiters indicating potential split points.
- `chunk_size` - The target size of each chunk, although actual chunks may be smaller.
- `chunk_overlap` - The number of overlapping characters for contextual continuity.

## Examples

```elixir
# Split a simple paragraph into chunks
text = "This is a sample text. It will be split into properly-sized chunks using the Chunker library."
separators = [".", "!"]
chunks = RecursiveSplit.recursive_split(text, separators, 50, 10)
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