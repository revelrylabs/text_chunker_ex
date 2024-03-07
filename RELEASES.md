# Releasing a new version

## Preparation
- [ ] Update the package version in `mix.exs`
- [ ] Update `CHANGELOG.md` to describe the new changes
- [ ] Update the package version badge and installation instructions in `README.md`

## Release Process
- [ ] Make sure all changes in the `Preparation` section are in `main`
- [ ] In GitHub, create, and publish, a new release with appropriate notes, and version matching the package version `mix.exs`
- [ ] The github actions workflow should automatically publish the package and docs to hex