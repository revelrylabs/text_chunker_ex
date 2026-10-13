defmodule TextChunker.Strategies.RecursiveChunk.Separators do
  # Separator configuration for the RecursiveChunk strategy.
  #
  # Each format gets a predefined list of separators. Order is crucial: the
  # splitting algorithm tries separators sequentially, so the first entry is
  # the highest-priority boundary (e.g. a markdown heading) and the list falls
  # through to paragraph, line, and finally word breaks.
  #
  # Hidden from the docs on purpose: these lists are an implementation detail
  # of the built-in strategy and may be tuned in minor releases.
  @moduledoc false

  @plaintext_formats [
    :doc,
    :docx,
    :epub,
    :latex,
    :odt,
    :pdf,
    :rtf,
    :vtt
  ]

  @doc false
  @spec get_separators(atom) :: [String.t()]
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
    empty_and_new_line_separators()
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
