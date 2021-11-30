# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## v2.1.1 (2019-02-18)

* speed improvements

  Benchmarked on 2018 Macbook Pro 13 (non-touch), results are just a snapshot
  and not averaged.

  before:

  ```
  ## ShortUUIDBench
  benchmark name                       iterations   average time
  encode/1 uuid binary                     500000   5.93 µs/op
  encode/1 uuid string not hyphenated      100000   10.71 µs/op
  encode/1 uuid string                     100000   15.35 µs/op
  encode/1 uuid string with braces         100000   17.22 µs/op
  decode/1                                 100000   15.05 µs/op
  ```

  after:

  ```
  ## ShortUUIDBench
  benchmark name                       iterations   average time
  encode/1 uuid binary                     500000   3.54 µs/op
  encode/1 uuid string not hyphenated      500000   4.12 µs/op
  encode/1 uuid string                     500000   4.54 µs/op
  encode/1 uuid string with braces         500000   5.84 µs/op
  decode/1                                 500000   7.97 µs/op
  ```

## v2.1.0 (2019-02-08)

* support directly encoding binary UUID

## v2.0.1 (2019-01-31)

* add error fallbacks for encode/decode for the case where input is not string
* update test cases
* update docs

## v2.0.0 (2019-01-29)

* drop support for custom alphabets
* use fixed alphabet _23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz_ as it seems to be by far the most widely used shortuuid alphabet
