## [Unreleased]

## [0.10.0](https://github.com/sequra/factiva-api-client/compare/v0.9.0...v0.10.0) (2025-02-10)


### Features

* add update_matches method to Factiva::Monitoring ([#33](https://github.com/sequra/factiva-api-client/issues/33)) ([d7550b3](https://github.com/sequra/factiva-api-client/commit/d7550b30824dc4dfc168dcf397ddae789abd879e))

## [0.9.0](https://github.com/sequra/factiva-api-client/compare/v0.8.0...v0.9.0) (2025-02-06)


### ⚠ BREAKING CHANGES

* Remove get_profile from Factiva::Monitoring ([#31](https://github.com/sequra/factiva-api-client/issues/31))

### Features

* Remove get_profile from Factiva::Monitoring ([#31](https://github.com/sequra/factiva-api-client/issues/31)) ([ffbcb09](https://github.com/sequra/factiva-api-client/commit/ffbcb09f15b748569c7405ab0a496e0885e39793))

## [0.8.0](https://github.com/sequra/factiva-api-client/compare/v0.7.0...v0.8.0) (2025-01-23)


### Features

* add is_match_valid and has_alerts filters to get_matches method ([#29](https://github.com/sequra/factiva-api-client/issues/29)) ([78bd651](https://github.com/sequra/factiva-api-client/commit/78bd651a8dc74ac6b8918f508ff572be1298994f))

## [0.7.0](https://github.com/sequra/factiva-api-client/compare/v0.6.0...v0.7.0) (2025-01-23)


### Features

* add get_profile method to Factiva::Monitoring ([#27](https://github.com/sequra/factiva-api-client/issues/27)) ([bedf4de](https://github.com/sequra/factiva-api-client/commit/bedf4debbef6f2461703ae791955b8296247a4bc))

## [0.6.0](https://github.com/sequra/factiva-api-client/compare/v0.5.0...v0.6.0) (2025-01-20)


### Features

* Add `update_association` method to `Factiva::Monitoring` ([#18](https://github.com/sequra/factiva-api-client/pull/18)) ([5053ea2](https://github.com/sequra/factiva-api-client/pull/18/commits/5053ea2462dca9a8d4f9c6a72160bff28554d303))
* Add `remove_association_from_case` method to `Factiva::Monitoring` ([#18](https://github.com/sequra/factiva-api-client/pull/18)) ([5053ea2](https://github.com/sequra/factiva-api-client/pull/18/commits/5053ea2462dca9a8d4f9c6a72160bff28554d303))
* Add pagination to the `get_matches` method in `Factiva::Monitoring` ([#18](https://github.com/sequra/factiva-api-client/pull/18)) ([5053ea2](https://github.com/sequra/factiva-api-client/pull/18/commits/5053ea2462dca9a8d4f9c6a72160bff28554d303))
* Handle Factiva empty body responses in  `Factiva::Monitoring#make_request` ([#20](https://github.com/sequra/factiva-api-client/pull/20)) ([87591b5](https://github.com/sequra/factiva-api-client/pull/20/commits/87591b57d41f4a897f5f1c49fce134239e0997e0))
* Add `delete_association` method to `Factiva::Monitoring` ([#20](https://github.com/sequra/factiva-api-client/pull/20)) ([582573d](https://github.com/sequra/factiva-api-client/pull/20/commits/582573daac45595441878fb7872ba9d02879819a))

## [0.5.0](https://github.com/sequra/factiva-api-client/compare/v0.4.0...v0.5.0) (2024-10-08)


### Features

* Adapt parameters for Ruby 3 ([#9](https://github.com/sequra/factiva-api-client/issues/9)) ([83487d5](https://github.com/sequra/factiva-api-client/commit/83487d55dd4a8cd90ecd24eaa1b9b34934445234))
* raise HTTP::TimeoutError for CircuitBreaker ([#13](https://github.com/sequra/factiva-api-client/issues/13)) ([f88bec2](https://github.com/sequra/factiva-api-client/commit/f88bec29f01085340d29e5748c9782e23c19b3a8))
* raise timeout error for circuit breaker ([#17](https://github.com/sequra/factiva-api-client/issues/17)) ([f329c20](https://github.com/sequra/factiva-api-client/commit/f329c2063dbd16dec3f4bc6aeea02a6c39cb757f))


### Bug Fixes

* revert refactoring ([#15](https://github.com/sequra/factiva-api-client/issues/15)) ([1f233f9](https://github.com/sequra/factiva-api-client/commit/1f233f9c074941db51e0f452b3885522935cc665))

## [0.1.0] - 2022-01-21

- Initial release
