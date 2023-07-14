# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## v3.0.0
* move most significant bit to the beginning of the encoded result similar to libraries in other languages (most importantly python shortuuid)
* drop support for decoding of un-padded ShortUUIDs
* drop support for formats other than regular hyphenated and unhyphenated UUIDs, MS format and binary UUIDs like are stored in PostgreSQL uuid type
* refactor code for better readability
* improve encode and decode performance

### Benchmarks
Results are not comparable to previous benchmarks due to them being run on a different system
  ```
  Operating System: macOS
  CPU Information: Apple M2 Max
  Number of Available Cores: 12
  Available memory: 32 GB
  Elixir 1.15.2
  Erlang 25.3.2.3

  Benchmark suite executing with the following configuration:
  warmup: 2 s
  time: 5 s
  memory time: 0 ns
  parallel: 1
  inputs: none specified
  ```

* v3.0.0
  ```
  Name                                        ips        average  deviation         median         99th %
  encode/1 binary uuid                  1212.57 K        0.82 μs  ±1995.67%        0.75 μs        1.00 μs
  encode/1 unhyphenated uuid string      788.79 K        1.27 μs   ±984.70%        1.13 μs        1.63 μs
  encode/1 hyphenated uuid string        753.56 K        1.33 μs  ±1106.96%        1.17 μs        1.67 μs
  encode/1 uuid string with braces       722.36 K        1.38 μs  ±1188.51%        1.21 μs        1.83 μs
  decode/1                                 1.15 M      868.43 ns  ±1506.27%         751 ns        1334 ns
  ```

* v2.1.1
  ```
  Name                                        ips        average  deviation         median         99th %
  encode/1 binary uuid                    1018.43 K        0.98 μs  ±1224.91%        0.88 μs        1.25 μs
  encode/1 unhyphenated uuid string        849.67 K        1.18 μs  ±1171.07%        1.08 μs        1.42 μs
  encode/1 hyphenated uuid string          731.91 K        1.37 μs   ±691.40%        1.29 μs        1.63 μs
  encode/1 uuid string with braces         569.16 K        1.76 μs   ±833.41%        1.63 μs        2.17 μs
  decode/1                                   1.00 M      996.37 ns   ±781.87%         918 ns        1376 ns
  ```

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