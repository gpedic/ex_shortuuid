# Changelog

**2.1.1**

* speed improvements

before
```
## ShortUUIDBench
benchmark name                       iterations   average time
encode/1 uuid binary                     500000   5.93 µs/op
encode/1 uuid string not hyphenated      100000   10.71 µs/op
encode/1 uuid string                     100000   15.35 µs/op
encode/1 uuid string with braces         100000   17.22 µs/op
decode/1                                 100000   15.05 µs/op
```

after
```
## ShortUUIDBench
benchmark name                       iterations   average time
encode/1 uuid binary                     500000   3.54 µs/op
encode/1 uuid string not hyphenated      500000   4.12 µs/op
encode/1 uuid string                     500000   4.54 µs/op
encode/1 uuid string with braces         500000   5.84 µs/op
decode/1                                 500000   7.97 µs/op
```

benchmarked on 2018 Macbook Pro 13 (non-touch), results are just a snapshot and not averaged

**2.1.0**

* support directly encoding binary UUID

**2.0.1**

* add error fallbacks for encode/decode for the case where input is not string
* update test cases
* update docs

**2.0.0**

* drop support for custom alphabets
* use fixed alphabet _23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz_ as it seems to be by far the most widely used shortuuid alphabet