defmodule RecursiveSplitTest do
  use ExUnit.Case

  alias Chunker.Separators
  alias Chunker.Splitters.RecursiveSplit

  @moduletag timeout: :infinity

  describe "plaintext splitter" do
    test "splits multiple sentences correctly" do
      chunk_size = 50
      chunk_overlap = 10

      text =
        "This is quite a short sentence. But what a headache does the darn thing create! Especially when splitting is involved. Do not look for meaning."

      separators = Separators.get_separators(:plaintext)
      result = RecursiveSplit.recursive_split(text, separators, chunk_size, chunk_overlap)

      expected_result = [
        "This is quite a short sentence. But what a",
        " what a headache does the darn thing create!",
        " create! Especially when splitting is involved. Do",
        " Do not look for meaning."
      ]

      assert result == expected_result
    end

    test "splits a piece of short text correctly" do
      chunk_size = 10
      chunk_overlap = 2
      text = "Hello there!\n General sdKenobi..."
      separators = Separators.get_separators(:plaintext)
      result = RecursiveSplit.recursive_split(text, separators, chunk_size, chunk_overlap)
      expected_result = ["Hello", " there!", "\n General", " sdKenobi.", "i..."]

      assert result == expected_result
    end

    test "splits a longer text correctly" do
      chunk_size = 10
      chunk_overlap = 2

      text = "This is a text splitter.\nIt splits text.\n\nThis is a completely separate paragraph of context."

      separators = Separators.get_separators(:plaintext)
      result = RecursiveSplit.recursive_split(text, separators, chunk_size, chunk_overlap)

      expected_result = [
        "This is a",
        " a text",
        " splitter.",
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

    test "copies the test from langchain" do
      chunk_size = 10
      chunk_overlap = 1
      text = "Hi.\n\nI'm Harrison.\n\nHow? Are? You?\nOkay then f f f f.
      This is a weird text to write, but gotta test the splittingggg some how.\n\n
      Bye!\n\n-H."
      separators = Separators.get_separators(:plaintext)
      result = RecursiveSplit.recursive_split(text, separators, chunk_size, chunk_overlap)

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
      chunk_size = 1000
      chunk_overlap = 200
      {:ok, text} = File.read("test/support/fixtures/document_fixtures/hamlet.txt")
      separators = Separators.get_separators(:plaintext)

      result =
        text
        |> RecursiveSplit.recursive_split(separators, chunk_size, chunk_overlap)
        |> Enum.take(2)

      expected_result = first_split_hamlet()

      assert result == expected_result
    end
  end

  describe "markdown splitter" do
    test "splits a simple markdown file" do
      chunk_size = 100
      chunk_overlap = 20
      {:ok, text} = File.read("test/support/fixtures/document_fixtures/test_file.md")

      separators = Separators.get_separators(:markdown)

      result = RecursiveSplit.recursive_split(text, separators, chunk_size, chunk_overlap)

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

  @doc """
  move this
  """
  def first_split_hamlet do
    [
      "THE TRAGEDY OF HAMLET, PRINCE OF DENMARK\n\n\nby William Shakespeare\n\n\n\nDramatis Personae\n\n  Claudius, King of Denmark.\n  Marcellus, Officer.\n  Hamlet, son to the former, and nephew to the present king.\n  Polonius, Lord Chamberlain.\n  Horatio, friend to Hamlet.\n  Laertes, son to Polonius.\n  Voltemand, courtier.\n  Cornelius, courtier.\n  Rosencrantz, courtier.\n  Guildenstern, courtier.\n  Osric, courtier.\n  A Gentleman, courtier.\n  A Priest.\n  Marcellus, officer.\n  Bernardo, officer.\n  Francisco, a soldier\n  Reynaldo, servant to Polonius.\n  Players.\n  Two Clowns, gravediggers.\n  Fortinbras, Prince of Norway.  \n  A Norwegian Captain.\n  English Ambassadors.\n\n  Getrude, Queen of Denmark, mother to Hamlet.\n  Ophelia, daughter to Polonius.\n\n  Ghost of Hamlet's Father.\n\n  Lords, ladies, Officers, Soldiers, Sailors, Messengers, Attendants.\n\n\n\n\n\nSCENE.- Elsinore.\n\n\nACT I. Scene I.\nElsinore. A platform before the Castle.",
      "\n\n  Ghost of Hamlet's Father.\n\n  Lords, ladies, Officers, Soldiers, Sailors, Messengers, Attendants.\n\n\n\n\n\nSCENE.- Elsinore.\n\n\nACT I. Scene I.\nElsinore. A platform before the Castle.\n\nEnter two Sentinels-[first,] Francisco, [who paces up and down\nat his post; then] Bernardo, [who approaches him].\n\n  Ber. Who's there.?\n  Fran. Nay, answer me. Stand and unfold yourself.\n  Ber. Long live the King!\n  Fran. Bernardo?\n  Ber. He.\n  Fran. You come most carefully upon your hour.\n  Ber. 'Tis now struck twelve. Get thee to bed, Francisco.\n  Fran. For this relief much thanks. 'Tis bitter cold,\n    And I am sick at heart.\n  Ber. Have you had quiet guard?\n  Fran. Not a mouse stirring.\n  Ber. Well, good night.\n    If you do meet Horatio and Marcellus,\n    The rivals of my watch, bid them make haste.\n\n                    Enter Horatio and Marcellus.  "
    ]
  end
end
