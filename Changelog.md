## 3.0.0

Breaking changes:

- Rename `.address_attributes`, `#address_lines`, … to something less ambiguous so it's clear whether we're talking about street address or all address attributes
    - Rename .address_attr_names  -> .street_address_attr_names
    - Rename #address_lines       -> #street_address_lines

    It was confusing having .address_attributes and #address_attributes referring to completely
    different sets of attributes.

- Change the default value for `street_address.attributes` config to a more strict Regex pattern to avoid
  matching `'foo_address'`: `column_names.grep(/^address$|^address_\d$/)`

Fixes:

- Fix `.states_for_country` to always return a `Carmen::RegionCollection` rather than sometimes a
- plain Array `[]`, so that we won't get an error if we try to call `coded` on the returned collection.

- Fix error with rails 5.2

Added:

- Add experimental support for `:on_unknown` config and state validation (added
    `validate_state_for_country`)


