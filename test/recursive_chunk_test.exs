defmodule TextChunkerTest do
  use ExUnit.Case

  alias TextChunker.TestHelpers

  @moduletag timeout: :infinity

  describe "chunker with plaintext separators" do
    test "splits multiple sentences correctly" do
      opts = [
        chunk_size: 50,
        chunk_overlap: 10,
        format: :plaintext
      ]

      text =
        "This is quite a short sentence. But what a headache does the darn thing create! Especially when splitting is involved. Do not look for meaning."

      result =
        text
        |> TextChunker.split(opts)
        |> TestHelpers.extract_text_from_chunks()

      expected_result = [
        "This is quite a short sentence. But what a",
        " what a headache does the darn thing create!",
        " create! Especially when splitting is involved. Do",
        " Do not look for meaning."
      ]

      assert result == expected_result
    end

    test "splits a piece of short text correctly" do
      opts = [
        chunk_size: 10,
        chunk_overlap: 2,
        format: :plaintext
      ]

      text = "Hello there!\n General sdKenobi..."
      result = text |> TextChunker.split(opts) |> TestHelpers.extract_text_from_chunks()
      expected_result = ["Hello", " there!", "\n General", " sdKenobi.", "i..."]

      assert result == expected_result
    end

    test "splits a longer text correctly" do
      opts = [
        chunk_size: 10,
        chunk_overlap: 2,
        format: :plaintext
      ]

      text = "This is a text chunker.\nIt splits text.\n\nThis is a completely separate paragraph of context."

      result = text |> TextChunker.split(opts) |> TestHelpers.extract_text_from_chunks()

      expected_result = [
        "This is a",
        " a text",
        " chunker.",
        "\nIt splits",
        " text.",
        "\n",
        "\nThis is a",
        " completel",
        "ely",
        " separate",
        " paragraph",
        " of",
        " context."
      ]

      assert result == expected_result
    end

    # This test examples adapted from Langchain by Harrison Chase,
    # for validation purposes.
    # Copyright (c) Harrison Chase
    # Licensed under the MIT License: https://opensource.org/licenses/MIT

    test "splits text as expected from Langchain" do
      opts = [
        chunk_size: 10,
        chunk_overlap: 1,
        format: :plaintext
      ]

      text = "Hi.\n\nI'm Harrison.\n\nHow? Are? You?\nOkay then f f f f.
      This is a weird text to write, but gotta test the splittingggg some how.\n\n
      Bye!\n\n-H."

      result = text |> TextChunker.split(opts) |> TestHelpers.extract_text_from_chunks()

      # double check licensing
      expected_result = [
        "Hi.",
        "\n",
        "\nI'm",
        " Harrison.",
        "\n",
        "\nHow? Are?",
        " You?",
        "\nOkay then",
        " f f f f.",
        "\n     ",
        "  This is",
        " a weird",
        " text to",
        " write,",
        " but gotta",
        " test the",
        " splitting",
        "gggg",
        " some how.",
        "\n",
        "\n",
        "\n     ",
        "  Bye!",
        "\n\n-H."
      ]

      assert result == expected_result
    end

    test "splits a huge file correctly" do
      opts = [
        chunk_size: 1000,
        chunk_overlap: 200,
        format: :plaintext
      ]

      {:ok, text} = File.read("test/support/fixtures/document_fixtures/hamlet.txt")

      result =
        text
        |> TextChunker.split(opts)
        |> TestHelpers.extract_text_from_chunks()
        |> Enum.take(2)

      expected_result = TestHelpers.first_chunk_hamlet()

      assert result == expected_result
    end

    test "works for emojis" do
      opts = [
        chunk_size: 10,
        chunk_overlap: 2,
        format: :plaintext
      ]

      text = "💻💊🤔🐇🕳️🕶🥋💥🤖🐙🤯❓️"
      result = text |> TextChunker.split(opts) |> TestHelpers.extract_text_from_chunks()

      expected_result =
        ["💻💊🤔🐇🕳️🕶🥋💥🤖🐙", "🤖🐙🤯❓️"]

      assert result == expected_result
    end

    test "works for composite emojis" do
      opts = [
        chunk_size: 5,
        chunk_overlap: 2
      ]

      text = "👨‍👩‍👧‍👦👍🏿"
      result = text |> TextChunker.split(opts) |> TestHelpers.extract_text_from_chunks()
      expected_result = ["👨‍👩‍👧‍👦👍🏿"]

      assert result == expected_result
    end

    test "splits text into chunks which have the same number of bytes as the original file" do
      {:ok, text} = File.read("test/support/fixtures/document_fixtures/hamlet.txt")

      opts = [
        chunk_size: 1000,
        chunk_overlap: 0,
        format: :plaintext
      ]

      byte_size_of_chunks =
        text
        |> TextChunker.split(opts)
        |> TestHelpers.extract_text_from_chunks()
        |> Enum.reduce(0, fn chunk, total -> byte_size(chunk) + total end)

      assert byte_size(text) == byte_size_of_chunks
    end

    test "splits text into chunks sized according to the get_chunk_size" do
      {:ok, text} = File.read("test/support/fixtures/document_fixtures/hamlet.txt")

      # Custom sizing: count 1-3 character word chunks as "tokens"
      token_counter = fn chunk ->
        ~r/\w{1,3}/u
        |> Regex.scan(chunk)
        |> length()
      end

      opts = [
        chunk_size: 1000,
        get_chunk_size: token_counter,
        chunk_overlap: 0,
        format: :plaintext
      ]

      chunks = TextChunker.split(text, opts)

      assert length(chunks) == 81

      for chunk <- chunks do
        assert token_counter.(chunk.text) <= 1000
      end
    end

    test "get_chunk_size function is used during chunk merging" do
      text = String.duplicate("hello world ", 50)

      # 1 token ≈ 4 chars
      token_fn = fn text -> max(1, div(String.length(text), 4)) end

      token_chunks =
        TextChunker.split(text,
          chunk_size: 100,
          chunk_overlap: 0,
          get_chunk_size: token_fn
        )

      char_chunks =
        TextChunker.split(text,
          chunk_size: 100,
          chunk_overlap: 0
        )

      assert length(token_chunks) < length(char_chunks),
             "Expected fewer token-based chunks than character-based chunks. " <>
               "Token chunks: #{length(token_chunks)}, Char chunks: #{length(char_chunks)}"

      for chunk <- token_chunks do
        size = token_fn.(chunk.text)

        assert size <= 100,
               "Chunk exceeds token limit: #{size} tokens (#{String.length(chunk.text)} chars)"
      end
    end

    test "splits text into chunks with lengths that match the original file" do
      {:ok, text} = File.read("test/support/fixtures/document_fixtures/hamlet.txt")

      [%{end_byte: last_byte_length} | _rest] =
        text
        |> TextChunker.split()
        |> Enum.reverse()

      assert byte_size(text) == last_byte_length
    end
  end

  describe "chunker with markdown separators" do
    test "splits a simple markdown file" do
      opts = [
        chunk_size: 100,
        chunk_overlap: 20,
        format: :markdown
      ]

      {:ok, text} = File.read("test/support/fixtures/document_fixtures/test_file.md")

      result = text |> TextChunker.split(opts) |> TestHelpers.extract_text_from_chunks()

      expected_result = [
        "# Foobar\n\nFoobar is a Python library for dealing with word pluralization.\n",
        "\n## Installation\n\nUse the package manager [pip](https://pip.pypa.io/en/stable/) to install foobar.",
        "\n\n```bash\npip install foobar\n```\n",
        "\n## Usage\n\n```python\nimport foobar\n\n# returns 'words'\nfoobar.pluralize('word')",
        "\n\n# returns 'geese'\nfoobar.pluralize('goose')",
        "\n\n# returns 'phenomenon'\nfoobar.singularize('phenomena')\n```\n",
        "\n## Contributing",
        "\n\nPull requests are welcome. For major changes, please open an issue first",
        "\nto discuss what you would like to change.",
        "\n\nPlease make sure to update tests as appropriate.\n",
        "\n## License\n\n[MIT](https://choosealicense.com/licenses/mit/)"
      ]

      assert result == expected_result
    end
  end

  describe "chunker with python separators" do
    test "splits a simple python file sensibly with no overlap" do
      opts = [
        chunk_size: 100,
        chunk_overlap: 0,
        format: :python
      ]

      {:ok, text} = File.read("test/support/fixtures/document_fixtures/test_code.py")

      result = text |> TextChunker.split(opts) |> TestHelpers.extract_text_from_chunks()

      expected_result =
        [
          ~s(class PetShop:\n    """Represents a pet shop with inventory and sales functionality."""),
          "\n\n    def __init__(self, name):\n        self.name = name\n        self.inventory = {}",
          "\n\n    def add_pet(self, pet_type, quantity):",
          ~s(\n        """Adds a specified quantity of a pet type to the inventory."""),
          "\n        if pet_type in self.inventory:\n            self.inventory[pet_type] += quantity",
          "\n        else:\n            self.inventory[pet_type] = quantity",
          "\n\n    def sell_pet(self, pet_type, quantity):",
          ~s(\n        """Sells a specified quantity of a pet type."""),
          "\n        if pet_type in self.inventory and self.inventory[pet_type] >= quantity:",
          "\n            self.inventory[pet_type] -= quantity\n            return True\n        else:",
          "\n            return False",
          "\n\n    def get_pet_count(self, pet_type):",
          ~s(\n        """Returns the current count of a specific pet type."""),
          "\n        return self.inventory.get(pet_type, 0)\n"
        ]

      assert result == expected_result
    end

    test "splits a simple python file sensibly with overlap" do
      opts = [
        chunk_size: 100,
        chunk_overlap: 50,
        format: :python
      ]

      {:ok, text} = File.read("test/support/fixtures/document_fixtures/test_code.py")

      result = text |> TextChunker.split(opts) |> TestHelpers.extract_text_from_chunks()

      expected_result =
        [
          ~s(class PetShop:\n    """Represents a pet shop with inventory and sales functionality."""),
          "\n\n    def __init__(self, name):\n        self.name = name\n        self.inventory = {}",
          "\n\n    def add_pet(self, pet_type, quantity):",
          ~s(\n        """Adds a specified quantity of a pet type to the inventory."""),
          "\n        if pet_type in self.inventory:\n            self.inventory[pet_type] += quantity",
          "\n            self.inventory[pet_type] += quantity\n        else:",
          "\n        else:\n            self.inventory[pet_type] = quantity",
          "\n\n    def sell_pet(self, pet_type, quantity):",
          ~s{\n    def sell_pet(self, pet_type, quantity):\n        """Sells a specified quantity of a pet type."""},
          "\n        if pet_type in self.inventory and self.inventory[pet_type] >= quantity:",
          "\n            self.inventory[pet_type] -= quantity\n            return True\n        else:",
          "\n            return True\n        else:\n            return False",
          "\n\n    def get_pet_count(self, pet_type):",
          ~s(\n        """Returns the current count of a specific pet type."""),
          "\n        return self.inventory.get(pet_type, 0)\n"
        ]

      assert result == expected_result
    end
  end

  describe "chunker with javascript separators" do
    test "splits a simple javascript file sensibly with no overlap" do
      opts = [
        chunk_size: 100,
        chunk_overlap: 0,
        format: :javascript
      ]

      {:ok, text} = File.read("test/support/fixtures/document_fixtures/test_code.js")

      result = text |> TextChunker.split(opts) |> TestHelpers.extract_text_from_chunks()

      expected_result =
        [
          "class PetShop {\n  constructor(name) {\n      this.name = name;\n      this.inventory = {};\n  }",
          "\n\n  addPet(petType, quantity) {\n    ",
          "  if (this.inventory[petType]) {\n          this.inventory[petType] += quantity;\n      } else {",
          "\n          this.inventory[petType] = quantity;\n      }\n  }",
          "\n\n  sellPet(petType, quantity) {\n    ",
          "  if (this.inventory[petType] && this.inventory[petType] >= quantity) {",
          "\n          this.inventory[petType] -= quantity;\n          return true;\n      } else {",
          "\n          return false;\n      }\n  }",
          "\n\n  getPetCount(petType) {\n      return this.inventory[petType] || 0; \n  }\n}\n"
        ]

      assert result == expected_result
    end

    test "splits a simple javascript file sensibly with overlap" do
      opts = [
        chunk_size: 100,
        chunk_overlap: 50,
        format: :javascript
      ]

      {:ok, text} = File.read("test/support/fixtures/document_fixtures/test_code.js")

      result = text |> TextChunker.split(opts) |> TestHelpers.extract_text_from_chunks()

      expected_result =
        [
          "class PetShop {\n  constructor(name) {\n      this.name = name;\n      this.inventory = {};\n  }",
          "\n\n  addPet(petType, quantity) {\n    ",
          "  if (this.inventory[petType]) {\n          this.inventory[petType] += quantity;\n      } else {",
          "\n      } else {\n          this.inventory[petType] = quantity;\n      }\n  }",
          "\n\n  sellPet(petType, quantity) {\n    ",
          "  if (this.inventory[petType] && this.inventory[petType] >= quantity) {",
          "\n          this.inventory[petType] -= quantity;\n          return true;\n      } else {",
          "\n          return true;\n      } else {\n          return false;\n      }\n  }",
          "\n\n  getPetCount(petType) {\n      return this.inventory[petType] || 0; \n  }\n}\n"
        ]

      assert result == expected_result
    end
  end

  describe "chunker with HTML separators" do
    test "splits an HTML file" do
      opts = [
        chunk_size: 100,
        chunk_overlap: 20,
        format: :html
      ]

      {:ok, text} = File.read("test/support/fixtures/document_fixtures/test_file.html")
      result = text |> TextChunker.split(opts) |> TestHelpers.extract_text_from_chunks()

      expected_result = [
        "<h1>Elixir: A Powerful Language for Building Scalable Applications</h1>\n",
        "<p>Elixir is a dynamic, functional programming language designed for building scalable and",
        " scalable and maintainable applications. It runs on the Erlang Virtual Machine (VM), which is known",
        " which is known for its robust concurrency and fault-tolerance capabilities. In this article, we'll",
        " this article, we'll explore the key features of Elixir and discuss different chunking approaches",
        " chunking approaches for Retrieval Augmented Generation (RAG).</p>",
        "\n\n",
        "<h2>Key Features of Elixir</h2>\n",
        "<ul>\n  ",
        "<li>Functional Programming: Elixir is built on the principles of functional programming, which",
        " programming, which emphasizes immutability, higher-order functions, and recursive algorithms.</li>",
        "\n  ",
        "<li>Concurrency and Scalability: Elixir leverages the power of the Erlang VM to provide lightweight",
        " provide lightweight processes and efficient message passing, enabling massive concurrency and",
        " concurrency and scalability.</li>",
        "\n  ",
        "<li>Fault-Tolerance: With its actor-based concurrency model and support for supervisors, Elixir",
        " supervisors, Elixir allows you to build fault-tolerant systems that can handle failures",
        " can handle failures gracefully.</li>",
        "\n  ",
        "<li>Metaprogramming: Elixir provides powerful metaprogramming capabilities through macros, allowing",
        " macros, allowing you to extend the language and write expressive and reusable code.</li>",
        "\n</ul>",
        "\n\n",
        "<article>\n  ",
        "<h3>Chunking Approaches for Retrieval Augmented Generation</h3>\n  ",
        "<p>Retrieval Augmented Generation (RAG) is a technique that combines information retrieval with",
        " retrieval with language generation to generate high-quality and informative text. Chunking, the",
        " text. Chunking, the process of breaking down text into smaller units, plays a crucial role in RAG.",
        " role in RAG. Let's explore different chunking approaches commonly used in Elixir:</p>",
        "\n  ",
        "<ol>\n    ",
        "<li>Sentence-based Chunking: This approach splits the text into individual sentences using",
        " sentences using punctuation markers such as periods, question marks, and exclamation points. Each",
        " points. Each sentence becomes a separate chunk, allowing for fine-grained retrieval and",
        " retrieval and generation.</li>",
        "\n    ",
        "<li>Paragraph-based Chunking: With this approach, the text is divided into paragraphs based on the",
        " based on the presence of newline characters or specific paragraph delimiters. Paragraphs provide a",
        " provide a coherent and self-contained unit of information suitable for RAG.</li>",
        "\n    ",
        "<li>Semantic Chunking: Semantic chunking involves analyzing the text and identifying meaningful",
        " meaningful semantic units or phrases. This can be achieved using techniques like named entity",
        " like named entity recognition, noun phrase extraction, or dependency parsing. Semantic chunks",
        " Semantic chunks capture the core concepts and ideas within the text.</li>",
        "\n    ",
        "<li>Custom Chunking: Elixir provides the flexibility to define custom chunking rules based on",
        " rules based on specific requirements. For example, you can chunk text based on a certain number of",
        " a certain number of words, specific delimiters, or regular expressions that match particular",
        " match particular patterns.</li>",
        "\n  </ol>\n  ",
        "<p>The choice of chunking approach depends on the nature of the text and the desired granularity of",
        " granularity of retrieval and generation. Elixir's powerful string manipulation and pattern matching",
        " pattern matching capabilities make it easy to implement various chunking strategies",
        " chunking strategies efficiently.</p>",
        "\n</article>",
        "\n\n",
        "<section>\n  ",
        "<h3>Benefits of Elixir/Erlang</h3>\n  ",
        "<h4>Elixir and Erlang offer several advantages over other language stacks when it comes to building",
        " comes to building scalable and fault-tolerant systems. Let's take a look at some of the key",
        " at some of the key benefits:</h4>",
        "\n  ",
        "<table>\n    <thead>\n      <tr>\n        <th>Benefit</th>\n        <th>Description</th>\n      </tr>",
        "\n      </tr>\n    </thead>\n    <tbody>\n      <tr>\n        <td>Concurrency and Scalability</td>",
        "\n        <td>Built-in support for lightweight processes and efficient message passing.</td>",
        "\n      </tr>\n      <tr>\n        <td>Fault-Tolerance</td>",
        "\n        <td>\"Let it crash\" philosophy and automatic recovery from failures.</td>\n      </tr>",
        "\n      </tr>\n      <tr>\n        <td>Hot Code Swapping</td>",
        "\n        <td>Update code without stopping the system, providing zero downtime.</td>\n      </tr>",
        "\n      </tr>\n      <tr>\n        <td>Distribution and Clustering</td>",
        "\n        <td>Built-in support for distributed systems and easy horizontal scaling.</td>\n      </tr>",
        "\n      </tr>\n      <tr>\n        <td>Ecosystem and Libraries</td>",
        "\n        <td>Growing ecosystem with a wide range of libraries and supportive community.</td>",
        "\n      </tr>\n    </tbody>\n  </table>\n  ",
        "<p>These benefits make Elixir and Erlang a compelling choice for building scalable, fault-tolerant,",
        " fault-tolerant, and maintainable systems, especially in domains like web development, real-time",
        " real-time applications, and distributed systems.</p>",
        "\n</section>",
        "\n\n",
        "<h5>Conclusion</h5>\n",
        "<p>Elixir's combination of functional programming, concurrency, and fault-tolerance makes it a",
        " makes it a powerful language for building scalable and maintainable RAG systems. By leveraging the",
        " By leveraging the appropriate chunking approaches and utilizing Elixir's strengths, you can create",
        " you can create efficient and high-quality retrieval augmented generation solutions.</p>",
        "\n\n",
        "<h6>© Elixir RAG. All rights reserved.</h6>"
      ]

      assert result == expected_result
    end
  end

  describe "rejects unsupported options" do
    test "rejects a chunk_overlap of -1" do
      opts = [
        chunk_overlap: -1
      ]

      result = TextChunker.split("this should fail", opts)
      assert result == {:error, "invalid value for :chunk_overlap option: expected non negative integer, got: -1"}
    end

    test "rejects a chunk_size of 0" do
      opts = [
        chunk_size: 0
      ]

      result = TextChunker.split("this should fail", opts)
      assert result == {:error, "invalid value for :chunk_size option: expected positive integer, got: 0"}
    end

    test "rejects an unsupported format" do
      opts = [
        format: :made_up_format
      ]

      result = TextChunker.split("this should fail", opts)

      assert result == {
               :error,
               "invalid value for :format option: expected one of [:doc, :docx, :elixir, :epub, :html, :javascript, :latex, :markdown, :odt, :pdf, :php, :plaintext, :python, :rtf, :ruby, :typescript, :vue], got: :made_up_format"
             }
    end

    test "rejects a strategy that is not currently supported" do
      opts = [
        strategy: UnsupportedModule
      ]

      result = TextChunker.split("this should fail", opts)

      assert result ==
               {:error,
                "invalid value for :strategy option: expected one of [TextChunker.Strategies.RecursiveChunk], got: UnsupportedModule"}
    end
  end

  describe "metadata tracking" do
    test "splits long text into multiple chunks with overlap" do
      text = String.duplicate("a", 100)

      chunk_1 = %TextChunker.Chunk{
        start_byte: 0,
        end_byte: 50,
        text: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      }

      chunk_2 = %TextChunker.Chunk{
        start_byte: 35,
        end_byte: 85,
        text: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      }

      chunk_3 = %TextChunker.Chunk{
        start_byte: 70,
        end_byte: 100,
        text: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      }

      result = TextChunker.split(text, chunk_size: 50, chunk_overlap: 15, format: :plaintext)

      assert [chunk_1, chunk_2, chunk_3] == result
    end

    test "chunks can perfectly reconstruct original text using byte positions" do
      text = """
      # Title

      This is a paragraph with some content.
      And another line here.

      ## Subtitle

      More content with different separators.
      - List item 1
      - List item 2

      Final paragraph.
      """

      chunks = TextChunker.split(text, chunk_size: 80, chunk_overlap: 20, format: :markdown)

      for chunk <- chunks do
        assert chunk.start_byte >= 0
        assert chunk.end_byte > chunk.start_byte
        assert chunk.end_byte <= byte_size(text)
      end

      for chunk <- chunks do
        expected_text = String.slice(text, chunk.start_byte, chunk.end_byte - chunk.start_byte)
        assert chunk.text == expected_text
      end

      sorted_chunks = Enum.sort_by(chunks, & &1.start_byte)

      assert List.first(sorted_chunks).start_byte == 0
      assert List.last(sorted_chunks).end_byte == byte_size(text)
    end

    test "handles duplicate text content with accurate byte positions" do
      text = "hello world hello there hello again"
      chunks = TextChunker.split(text, chunk_size: 15, chunk_overlap: 5, format: :plaintext)
      hello_chunks = Enum.filter(chunks, &String.contains?(&1.text, "hello"))
      assert length(hello_chunks) > 1

      for chunk <- hello_chunks do
        reconstructed = String.slice(text, chunk.start_byte, chunk.end_byte - chunk.start_byte)
        assert chunk.text == reconstructed
      end

      positions = Enum.map(hello_chunks, & &1.start_byte)
      unique_positions = Enum.uniq(positions)
      assert length(unique_positions) > 1
    end

    test "maintains byte accuracy with complex separators and unicode" do
      text = """
      ```elixir
      def hello(world) do
        "Hello 🌍!"
      end
      ```

      ## Features 🚀

      - Emoji support 😀
      - Unicode strings 中文
      - Multi-byte chars 👩‍🚒
      """

      chunks = TextChunker.split(text, chunk_size: 60, chunk_overlap: 10, format: :markdown)

      for chunk <- chunks do
        # Extract the exact bytes from original text using binary pattern matching:
        # Skip start_byte bytes, capture (end_byte - start_byte) bytes, ignore the rest
        <<_::binary-size(chunk.start_byte), chunk_bytes::binary-size(chunk.end_byte - chunk.start_byte), _::binary>> =
          text

        assert chunk.text == chunk_bytes
        expected_end = chunk.start_byte + byte_size(chunk.text)
        assert chunk.end_byte == expected_end
      end
    end

    test "empty and single character edge cases maintain accurate positions" do
      text = "a"
      chunks = TextChunker.split(text, chunk_size: 10, chunk_overlap: 2, format: :plaintext)

      assert length(chunks) == 1
      chunk = List.first(chunks)
      assert chunk.start_byte == 0
      assert chunk.end_byte == 1
      assert chunk.text == "a"
      text = ""
      chunks = TextChunker.split(text, chunk_size: 10, chunk_overlap: 2, format: :plaintext)

      for chunk <- chunks do
        assert chunk.start_byte >= 0
        assert chunk.end_byte >= chunk.start_byte
      end
    end

    test "chunk overlap positions are calculated correctly" do
      text = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

      chunks = TextChunker.split(text, chunk_size: 10, chunk_overlap: 3, format: :plaintext)

      for i <- 1..(length(chunks) - 1) do
        prev_chunk = Enum.at(chunks, i - 1)
        curr_chunk = Enum.at(chunks, i)

        overlap_start = curr_chunk.start_byte
        _overlap_expected = prev_chunk.end_byte - 3

        assert overlap_start < prev_chunk.end_byte
      end
    end
  end

  describe "error handling" do
    test "returns error chunk for empty text" do
      chunks = TextChunker.split("", chunk_size: 100, chunk_overlap: 0, format: :plaintext)

      assert length(chunks) == 1
      chunk = List.first(chunks)
      assert chunk.start_byte == 0
      assert chunk.end_byte == 0
      assert String.contains?(chunk.text, "No chunks created")
    end
  end

  describe "fallback separator behavior" do
    @non_matching_text "Cool text here to summarize without any special formatting"
    @supported_formats [
      :doc,
      :docx,
      :elixir,
      :epub,
      :html,
      :javascript,
      :latex,
      :markdown,
      :odt,
      :pdf,
      :php,
      :plaintext,
      :python,
      :rtf,
      :ruby,
      :typescript,
      :vue
    ]

    test "handles large repetitive text" do
      large_content = String.duplicate("a", 150_000)

      opts = [
        chunk_size: 1000,
        chunk_overlap: 0,
        format: :markdown
      ]

      chunks = TextChunker.split(large_content, opts)

      for chunk <- Enum.drop(chunks, -1) do
        assert String.length(chunk.text) == 1000
      end

      assert large_content ==
               chunks
               |> TestHelpers.extract_text_from_chunks()
               |> Enum.join("")
    end

    test "all formats respect chunk size limits when falling back to character splitting" do
      chunk_size = 10

      Enum.map(@supported_formats, fn format ->
        chunks = TextChunker.split(@non_matching_text, chunk_size: chunk_size, format: format)

        Enum.map(chunks, fn chunk ->
          assert byte_size(chunk.text) <= chunk_size,
                 "Format #{format} produced chunk larger than #{chunk_size}: #{inspect(chunk.text)}"
        end)
      end)
    end

    test "single long word is split correctly across all formats" do
      long_word = "supercalifragilisticexpialidocious"

      Enum.map(@supported_formats, fn format ->
        chunks = TextChunker.split(long_word, chunk_size: 10, format: format)

        Enum.map(chunks, fn chunk ->
          assert byte_size(chunk.text) <= 10
        end)

        assert length(chunks) > 1
        assert String.starts_with?(hd(chunks).text, "super")
        last_chunk = List.last(chunks).text
        assert String.length(last_chunk) <= 10
      end)
    end

    test "format-specific separators take precedence over fallback" do
      markdown_text = "## Header\nContent here\n### Subheader\nMore content"
      chunks = TextChunker.split(markdown_text, chunk_size: 30, format: :markdown)

      chunk_texts = Enum.map(chunks, & &1.text)
      assert Enum.any?(chunk_texts, &String.starts_with?(&1, "## Header"))

      python_text = "class Test:\n    def method(self):\n        return 'test'"
      chunks = TextChunker.split(python_text, chunk_size: 30, format: :python)

      chunk_texts = Enum.map(chunks, & &1.text)
      assert Enum.any?(chunk_texts, &String.contains?(&1, "class Test:"))
    end

    test "plaintext-like formats produce consistent results" do
      plaintext_formats = [:doc, :docx, :epub, :latex, :odt, :pdf, :rtf, :plaintext]

      baseline_chunks =
        @non_matching_text
        |> TextChunker.split(chunk_size: 15, format: :plaintext)
        |> TestHelpers.extract_text_from_chunks()

      Enum.map(plaintext_formats, fn format ->
        chunks =
          @non_matching_text
          |> TextChunker.split(chunk_size: 15, format: format)
          |> TestHelpers.extract_text_from_chunks()

        assert chunks == baseline_chunks,
               "Format #{format} should behave like plaintext for non-matching text"
      end)
    end
  end
end
