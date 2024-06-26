defmodule TextChunker.Strategies.RecursiveChunk.Separators do
  @moduledoc """
  Handles separator configuration for the RecursiveChunk text chunking strategy.

  Provides predefined lists of separators tailored for different text formats. The order of separators is crucial, as the splitting algorithm prioritizes them sequentially.

  **Key Features:**

  * **Format-Specific Separators:** Customizes splitting behavior based on formats like Markdown, plain text, Elixir, and others.
  * **Prioritized Splitting:** Attempts to split text using the highest-priority separator applicable to the text's content.\
  """

  @plaintext_formats [
    :doc,
    :docx,
    :epub,
    :latex,
    :odt,
    :pdf,
    :rtf
  ]

  @spec get_separators(atom) :: [String.t()]
  @doc """
  Returns a list of separators that will be used to split the document of the given format
  """
  def get_separators(:markdown) do
    [
      "\n## ",
      "\n### ",
      "\n#### ",
      "\n##### ",
      "\n###### ",
      "```\n\n",
      "\n\n___\n\n",
      "\n\n---\n\n",
      "\n\n***\n\n"
    ] ++ empty_and_new_line_separators()
  end

  def get_separators(:plaintext) do
    empty_and_new_line_separators() ++ [""]
  end

  def get_separators(:elixir) do
    [
      # top-level declarations
      "\ndefmodule ",
      "\ndefprotocol ",
      "\ndefimpl ",
      # nested declarations
      "  defmodule ",
      "  defprotocol ",
      "  defimpl ",
      # functions
      "@doc \"\"\"",
      "  def ",
      "  defp ",
      # control flow
      "  with ",
      "  cond ",
      "  case ",
      "  if "
    ] ++ empty_and_new_line_separators()
  end

  def get_separators(:ruby) do
    [
      "\nclass ",
      "  class ",
      "\n##",
      "  ##",
      "  private\n",
      "\ndef ",
      "  def ",
      "  if ",
      "  unless ",
      "  while ",
      "  for ",
      "  do ",
      "  begin ",
      "  rescue "
    ] ++ empty_and_new_line_separators()
  end

  def get_separators(:php) do
    [
      "\nclass ",
      "  class ",
      "\n/**",
      "  /**",
      "\nfunction ",
      "  function ",
      "public function ",
      "protected function ",
      "private function ",
      "  if ",
      "  foreach ",
      "  while ",
      "  do ",
      "  switch ",
      "  case "
    ] ++ empty_and_new_line_separators()
  end

  def get_separators(:python) do
    [
      "\nclass ",
      "\ndef ",
      "\n\tdef "
    ] ++ empty_and_new_line_separators()
  end

  def get_separators(:vue) do
    [
      "<script",
      "<section",
      "<table",
      "<template"
    ] ++ get_separators(:javascript)
  end

  def get_separators(:javascript) do
    [
      "\nclass ",
      "  class ",
      "\nfunction ",
      "  function ",
      "\nexport const ",
      "\nexport default ",
      "\nconst ",
      "  const ",
      "  let ",
      "  var ",
      "  if ",
      "  for ",
      "  while ",
      "  switch ",
      "  case ",
      "  default "
    ] ++ empty_and_new_line_separators()
  end

  def get_separators(:html) do
    [
      "<h1",
      "<h2",
      "<h3",
      "<h4",
      "<h5",
      "<h6",
      "<p",
      "<ul",
      "<ol",
      "<li",
      "<article",
      "<section",
      "<table"
    ] ++
      empty_and_new_line_separators()
  end

  def get_separators(:typescript), do: get_separators(:javascript)

  def get_separators(format) when format in @plaintext_formats, do: get_separators(:plaintext)

  defp empty_and_new_line_separators do
    [
      "\n\n",
      "\n",
      " "
    ]
  end
end
