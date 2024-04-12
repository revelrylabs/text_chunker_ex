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
        ["💻💊🤔🐇🕳️🕶🥋💥🤖", "💥🤖🐙🤯❓️"]

      assert result == expected_result
    end

    test "works for composite emojis" do
      opts = [
        chunk_size: 5,
        chunk_overlap: 2
      ]

      text = "👨‍👩‍👧‍👦👍🏿"
      result = text |> TextChunker.split(opts) |> TestHelpers.extract_text_from_chunks()
      expected_result = ["👨‍👩‍👧", "‍👧‍👦👍", "👦👍🏿"]

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
          "class PetShop:\n    \"\"\"Represents a pet shop with inventory and sales functionality.\"\"\"",
          "\n\n    def __init__(self, name):\n        self.name = name\n        self.inventory = {}",
          "\n\n    def add_pet(self, pet_type, quantity):",
          "\n        \"\"\"Adds a specified quantity of a pet type to the inventory.\"\"\"",
          "\n        if pet_type in self.inventory:\n            self.inventory[pet_type] += quantity",
          "\n        else:\n            self.inventory[pet_type] = quantity",
          "\n\n    def sell_pet(self, pet_type, quantity):",
          "\n        \"\"\"Sells a specified quantity of a pet type.\"\"\"",
          "\n        if pet_type in self.inventory and self.inventory[pet_type] >= quantity:",
          "\n            self.inventory[pet_type] -= quantity\n            return True\n        else:",
          "\n            return False",
          "\n\n    def get_pet_count(self, pet_type):",
          "\n        \"\"\"Returns the current count of a specific pet type.\"\"\"",
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
          "class PetShop:\n    \"\"\"Represents a pet shop with inventory and sales functionality.\"\"\"",
          "\n\n    def __init__(self, name):\n        self.name = name\n        self.inventory = {}",
          "\n\n    def add_pet(self, pet_type, quantity):",
          "\n        \"\"\"Adds a specified quantity of a pet type to the inventory.\"\"\"",
          "\n        if pet_type in self.inventory:\n            self.inventory[pet_type] += quantity",
          "\n            self.inventory[pet_type] += quantity\n        else:",
          "\n        else:\n            self.inventory[pet_type] = quantity",
          "\n\n    def sell_pet(self, pet_type, quantity):",
          "\n    def sell_pet(self, pet_type, quantity):\n        \"\"\"Sells a specified quantity of a pet type.\"\"\"",
          "\n        if pet_type in self.inventory and self.inventory[pet_type] >= quantity:",
          "\n            self.inventory[pet_type] -= quantity\n            return True\n        else:",
          "\n            return True\n        else:\n            return False",
          "\n\n    def get_pet_count(self, pet_type):",
          "\n        \"\"\"Returns the current count of a specific pet type.\"\"\"",
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
               "invalid value for :format option: expected one of [:doc, :docx, :epub, :latex, :odt, :pdf, :rtf, :markdown, :plaintext, :elixir, :ruby, :php, :python, :vue, :javascript, :typescript], got: :made_up_format"
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
end
