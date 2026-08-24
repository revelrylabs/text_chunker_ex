%{
  configs: [
    %{
      name: "default",
      strict: true,
      checks: [
        # The recursive chunk assembly loops legitimately nest to depth 3.
        {Credo.Check.Refactor.Nesting, max_nesting: 3}
      ]
    }
  ]
}
