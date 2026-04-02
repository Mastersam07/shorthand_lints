## [v0.2.0] - 2026-04-02
### :sparkles: New Features
- [`f9ff82c`](https://github.com/Mastersam07/shorthand_lints/commit/f9ff82c9c63618aeb9103c212501a930ebfb0c9a) - support ?? operator as type context for dot shorthand *(commit by [@Mastersam07](https://github.com/Mastersam07))*
- [`b6d750b`](https://github.com/Mastersam07/shorthand_lints/commit/b6d750b8fb8409682fbf1cc328540a4f1f28d743) - detect type context for collections with inferred type args *(commit by [@Mastersam07](https://github.com/Mastersam07))*
- [`d336635`](https://github.com/Mastersam07/shorthand_lints/commit/d336635d519e2deb54b9fa3eba00f9331dc8ac62) - support if/for/spread elements in typed collections *(commit by [@Mastersam07](https://github.com/Mastersam07))*

### :bug: Bug Fixes
- [`f26a98a`](https://github.com/Mastersam07/shorthand_lints/commit/f26a98a300129efd519affc705f52dd1bc5c8381) - unwrap FutureOr<T> in prefer_returning_shorthands *(commit by [@Mastersam07](https://github.com/Mastersam07))*

### :recycle: Refactors
- [`5346e87`](https://github.com/Mastersam07/shorthand_lints/commit/5346e879699c25cf7dfebefe36f4e2356d1a27fe) - remove null assertions and dead code, update examples *(commit by [@Mastersam07](https://github.com/Mastersam07))*

### :wrench: Chores
- [`e73177d`](https://github.com/Mastersam07/shorthand_lints/commit/e73177d1fe01ce2a69a53d4c823cc18e65210c89) - update installation example *(commit by [@Mastersam07](https://github.com/Mastersam07))*


## [v0.1.1] - 2026-04-02
### :bug: Bug Fixes
- [`de448c4`](https://github.com/Mastersam07/shorthand_lints/commit/de448c4f2f3eb39222027940d4e1188c27d3334d) - prevent constructor rule from flagging subtype assignments *(commit by [@Mastersam07](https://github.com/Mastersam07))*

### :wrench: Chores
- [`2efd4f1`](https://github.com/Mastersam07/shorthand_lints/commit/2efd4f1240b70736c44d31ea3ab0e9168a7024e2) - fix failing release ci *(commit by [@Mastersam07](https://github.com/Mastersam07))*


## 0.1.0

- Initial release.
- `prefer_dot_shorthand_for_enums`: lint rule for enum value shorthand.
- `prefer_dot_shorthand_for_constructors`: lint rule for constructor shorthand.
- `prefer_dot_shorthand_for_statics`: lint rule for static member shorthand.
- `prefer_returning_shorthands`: lint rule for return statement shorthand.
- `avoid_nested_shorthands`: lint rule flagging nested dot shorthands.
- Quick fix: "Use dot shorthand" for all prefer_* rules.
[v0.1.1]: https://github.com/Mastersam07/shorthand_lints/compare/v0.1.0...v0.1.1
[v0.2.0]: https://github.com/Mastersam07/shorthand_lints/compare/v0.1.1...v0.2.0
