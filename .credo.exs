%{
  configs: [
    %{
      name: "default",
      strict: true,
      checks: [
        {Credo.Check.Refactor.Nesting, max_nesting: 3}
      ]
    }
  ]
}
