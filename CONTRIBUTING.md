# Contributing and Development

## Development Setup

1. Make sure you have Elixir 1.15+ installed
1. Clone the repo
1. Run `mix deps.get`
1. Run `mix test`

## Submitting Changes

1. Fork the project
1. Create a new topic branch to contain your feature, change, or fix.
1. Make sure all the tests are still passing.
1. Implement your feature, change, or fix. Make sure to write tests, update and/or add documentation.
1. Push your topic branch up to your fork.
1. Open a Pull Request with a clear title and description.

## AI-Assisted Contributions

Using AI tools to help write code, tests, issues, or pull requests is welcome
here. The quality bar is the same *regardless* of how a contribution was produced:

- You are the author. You must understand your change, be able to explain it,
  and be able to respond to review feedback about it.
- Run the checks before submitting: `mix test`, `mix format`, and
  `mix dialyzer` should all pass locally.
- Verify claims yourself. Do not submit issues or PR descriptions containing
  unverified AI output (for example, a bug report speculating about behavior
  without a reproduction, or a description of changes the diff does not make).
- I really don't care if you used AI or not: I care that your contribution is a best-effort attempt to improve the repo!