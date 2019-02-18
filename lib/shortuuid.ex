defmodule ShortUUID do
  @moduledoc """

  ShortUUID - generate concise, unambiguous, URL-safe UUIDs

  ## Installation

  Add ShortUUID to your list of dependencies in `mix.exs`:

      def deps do
        [{:shortuuid, "~> #{ShortUUID.Mixfile.project()[:version] |> String.slice(0, 3)}"}]
      end


  `encode/1` will translate UUIDs to base57 using lowercase and uppercase letters
  and digits while avoiding similar-looking characters such as l, 1, I, O and 0.

  ## Typical usage

  ShortUUID strives to do one thing well, encode UUIDs. To generate the UUIDs
  use any UUID library you like. Some of options out there are
  [Ecto](https://hexdocs.pm/ecto/Ecto.UUID.html),
  [Elixir UUID](https://github.com/zyro/elixir-uuid) and [Erlang UUID](https://github.com/okeuday/uuid).

  ## Notes

  The output is padded to a length of 22 with the first character of the alphabet (2).

      iex> ShortUUID.encode!("00000000-0000-0000-0000-000000000000")
      "2222222222222222222222"


      iex> ShortUUID.encode!("00000001-0001-0001-0001-000000000001")
      "UD6ibhr3V4YXvriP822222"


      iex> ShortUUID.decode!("UD6ibhr3V4YXvriP822222")
      "00000001-0001-0001-0001-000000000001"

  The input format is quite flexible as any non base16 chars are stripped from the input
  which is then downcased, however only the following formats are covered by tests thus
  guaranteed to work.

  * `2a162ee5-02f4-4701-9e87-72762cbce5e2`
  * `2a162ee502f447019e8772762cbce5e2`
  * `{2a162ee5-02f4-4701-9e87-72762cbce5e2}`
  * `{2a162ee502f447019e8772762cbce5e2}`

  Letter case is not relevant.

  Also supported since `v2.1.0` is the encoding of binary UUIDs

      iex> ShortUUID.encode!(<<0xFA, 0x62, 0xAF, 0x80, 0xA8, 0x61, 0x45, 0x6C, 0xAB, 0x77, 0xD5, 0x67, 0x7E, 0x2E, 0x8B, 0xA8>>)
      "PuQURs6h2XSBBVNgqSHJZn"

  ## Using ShortUUID with Ecto

  If you would like to use ShortUUIDs with Ecto check out [ecto_shortuuid](https://github.com/gpedic/ecto_shortuuid).

  ## Acknowledgments
    This project was inspired by [skorokithakis/shortuuid](https://github.com/skorokithakis/shortuuid).
  """

  @alphabet "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  @alphabet_tuple @alphabet
                  |> String.split("", trim: true)
                  |> List.to_tuple()

  @doc """
  Encode a UUID to ShortUUID.

  ## Examples

      iex> ShortUUID.encode("2a162ee5-02f4-4701-9e87-72762cbce5e2")
      {:ok, "keATfB8JP2ggT7U9JZrpV9"}

  """
  # def encode(<< b1::2,  b2::6,  b3::6,  b4::6,  b5::6,  b6::6,  b7::6,  b8::6,  b9::6, b10::6, b11::6, b12::6, b13::6,
  #               b14::6, b15::6, b16::6, b17::6, b18::6, b19::6, b20::6, b21::6, b22::6>>) do
  #   <<e(b1), e(b2), e(b3), e(b4), e(b5), e(b6), e(b7), e(b8), e(b9), e(b10), e(b11), e(b12), e(b13),
  #     e(b14), e(b15), e(b16), e(b17), e(b18), e(b19), e(b20), e(b21), e(b22)>>
  # catch
  #   :error -> :error
  # else
  #   encoded -> {:ok, encoded}
  # end

  @spec encode(binary) :: {:ok, String.t()} | {:error, String.t()}
  def encode(<<uuid::128>>) do
    {:ok, uuid |> int_to_string |> pad_shortuuid}
  end

  def encode(
        <<a1, a2, a3, a4, a5, a6, a7, a8, ?-, b1, b2, b3, b4, ?-, c1, c2, c3, c4, ?-, d1, d2, d3,
          d4, ?-, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12>>
      ) do
    encode(
      <<a1, a2, a3, a4, a5, a6, a7, a8, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, d4, e1, e2,
        e3, e4, e5, e6, e7, e8, e9, e10, e11, e12>>
    )
  end

  def encode(
        <<a1, a2, a3, a4, a5, a6, a7, a8, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, d4, e1, e2,
          e3, e4, e5, e6, e7, e8, e9, e10, e11, e12>>
      ) do
    try do
      <<b(a1)::4, b(a2)::4, b(a3)::4, b(a4)::4, b(a5)::4, b(a6)::4, b(a7)::4, b(a8)::4, b(b1)::4,
        b(b2)::4, b(b3)::4, b(b4)::4, b(c1)::4, b(c2)::4, b(c3)::4, b(c4)::4, b(d1)::4, b(d2)::4,
        b(d3)::4, b(d4)::4, b(e1)::4, b(e2)::4, b(e3)::4, b(e4)::4, b(e5)::4, b(e6)::4, b(e7)::4,
        b(e8)::4, b(e9)::4, b(e10)::4, b(e11)::4, b(e12)::4>>
    catch
      :error -> {:error, "Invalid UUID"}
    else
      binary -> encode(binary)
    end
  end

  def encode(uuid) when is_binary(uuid) do
    stripped_uuid = strip_uuid(uuid)

    case stripped_uuid |> byte_size() == 32 do
      true -> encode(stripped_uuid)
      _anything_else -> {:error, "Invalid UUID"}
    end
  end

  def encode(_), do: {:error, "Invalid UUID"}

  @doc """
  Encode a UUID to ShortUUID.

  Similar to `encode/1` but raises an ArgumentError if it cannot process the UUID.

  ## Examples

      iex> ShortUUID.encode!("2a162ee5-02f4-4701-9e87-72762cbce5e2")
      "keATfB8JP2ggT7U9JZrpV9"

  """
  @spec encode!(binary) :: String.t() | no_return()
  def encode!(uuid) do
    case encode(uuid) do
      {:ok, encoded_uuid} ->
        encoded_uuid

      {:error, msg} ->
        raise ArgumentError, message: msg
    end
  end

  @spec int_to_string(non_neg_integer(), maybe_improper_list()) :: String.t()
  defp int_to_string(number, acc \\ [])

  defp int_to_string(number, acc) when number > 0 do
    # int_to_string(div(number, 57), [acc | <<e(rem(number, 57))>>])
    int_to_string(div(number, 57), [acc | elem(@alphabet_tuple, rem(number, 57))])
  end

  defp int_to_string(0, acc), do: acc |> to_string

  @spec strip_uuid(binary) :: binary
  defp strip_uuid(uuid) do
    for <<c <- uuid>>, v(c), into: "", do: <<c>>
  end

  defp format_uuid(
         <<a1, a2, a3, a4, a5, a6, a7, a8, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, d4, e1, e2,
           e3, e4, e5, e6, e7, e8, e9, e10, e11, e12>>
       ) do
    <<c(a1), c(a2), c(a3), c(a4), c(a5), c(a6), c(a7), c(a8), ?-, c(b1), c(b2), c(b3), c(b4), ?-,
      c(c1), c(c2), c(c3), c(c4), ?-, c(d1), c(d2), c(d3), c(d4), ?-, c(e1), c(e2), c(e3), c(e4),
      c(e5), c(e6), c(e7), c(e8), c(e9), c(e10), c(e11), c(e12)>>
  end

  @doc """
  Decode a ShortUUID.

  ## Examples

      iex> ShortUUID.decode("keATfB8JP2ggT7U9JZrpV9")
      {:ok, "2a162ee5-02f4-4701-9e87-72762cbce5e2"}

  """
  @spec decode(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def decode(
        <<c1::8, c2::8, c3::8, c4::8, c5::8, c6::8, c7::8, c8::8, c9::8, c10::8, c11::8, c12::8,
          c13::8, c14::8, c15::8, c16::8, c17::8, c18::8, c19::8, c20::8, c21::8, c22::8>>
      ) do
    [
      d(c22),
      d(c21),
      d(c20),
      d(c19),
      d(c18),
      d(c17),
      d(c16),
      d(c15),
      d(c14),
      d(c13),
      d(c12),
      d(c11),
      d(c10),
      d(c9),
      d(c8),
      d(c7),
      d(c6),
      d(c5),
      d(c4),
      d(c3),
      d(c2),
      d(c1)
    ]
    |> Enum.reduce(0, fn index, acc ->
      acc * 57 + index
    end)
    |> Integer.to_string(16)
    |> pad_uuid
    |> format_uuid
  catch
    :error -> {:error, "Invalid input"}
  else
    decoded -> {:ok, decoded}
  end

  def decode(input) when is_binary(input) and byte_size(input) < 22 do
    pad_shortuuid(input) |> decode
  end

  def decode(_), do: {:error, "Invalid input"}

  @doc """
  Decode a ShortUUID.

  Similar to `decode/1` but raises an ArgumentError if the encoded UUID is invalid.

  ## Examples

      iex> ShortUUID.decode!("keATfB8JP2ggT7U9JZrpV9")
      "2a162ee5-02f4-4701-9e87-72762cbce5e2"
  """
  @spec decode!(String.t()) :: String.t() | no_return()
  def decode!(string) do
    case decode(string) do
      {:ok, uuid} -> uuid
      {:error, message} -> raise ArgumentError, message: message
    end
  end

  @spec pad_shortuuid(binary()) :: binary()
  defp pad_shortuuid(<<_::176>> = shortuuid), do: shortuuid
  defp pad_shortuuid(shortuuid), do: pad_shortuuid(shortuuid <> <<50>>)

  @spec pad_uuid(binary()) :: binary()
  defp pad_uuid(<<_::binary-size(32)>> = uuid), do: uuid
  defp pad_uuid(uuid), do: pad_uuid(<<48>> <> uuid)

  @compile {:inline, b: 1}

  defp b(?0), do: 0
  defp b(?1), do: 1
  defp b(?2), do: 2
  defp b(?3), do: 3
  defp b(?4), do: 4
  defp b(?5), do: 5
  defp b(?6), do: 6
  defp b(?7), do: 7
  defp b(?8), do: 8
  defp b(?9), do: 9
  defp b(?A), do: 10
  defp b(?B), do: 11
  defp b(?C), do: 12
  defp b(?D), do: 13
  defp b(?E), do: 14
  defp b(?F), do: 15
  defp b(?a), do: 10
  defp b(?b), do: 11
  defp b(?c), do: 12
  defp b(?d), do: 13
  defp b(?e), do: 14
  defp b(?f), do: 15
  defp b(_), do: throw(:error)

  @compile {:inline, c: 1}

  defp c(?0), do: ?0
  defp c(?1), do: ?1
  defp c(?2), do: ?2
  defp c(?3), do: ?3
  defp c(?4), do: ?4
  defp c(?5), do: ?5
  defp c(?6), do: ?6
  defp c(?7), do: ?7
  defp c(?8), do: ?8
  defp c(?9), do: ?9
  defp c(?A), do: ?a
  defp c(?B), do: ?b
  defp c(?C), do: ?c
  defp c(?D), do: ?d
  defp c(?E), do: ?e
  defp c(?F), do: ?f
  defp c(?a), do: ?a
  defp c(?b), do: ?b
  defp c(?c), do: ?c
  defp c(?d), do: ?d
  defp c(?e), do: ?e
  defp c(?f), do: ?f
  defp c(_), do: throw(:error)

  @compile {:inline, d: 1}

  defp d(?2), do: 0
  defp d(?3), do: 1
  defp d(?4), do: 2
  defp d(?5), do: 3
  defp d(?6), do: 4
  defp d(?7), do: 5
  defp d(?8), do: 6
  defp d(?9), do: 7
  defp d(?A), do: 8
  defp d(?B), do: 9
  defp d(?C), do: 10
  defp d(?D), do: 11
  defp d(?E), do: 12
  defp d(?F), do: 13
  defp d(?G), do: 14
  defp d(?H), do: 15
  defp d(?J), do: 16
  defp d(?K), do: 17
  defp d(?L), do: 18
  defp d(?M), do: 19
  defp d(?N), do: 20
  defp d(?P), do: 21
  defp d(?Q), do: 22
  defp d(?R), do: 23
  defp d(?S), do: 24
  defp d(?T), do: 25
  defp d(?U), do: 26
  defp d(?V), do: 27
  defp d(?W), do: 28
  defp d(?X), do: 29
  defp d(?Y), do: 30
  defp d(?Z), do: 31
  defp d(?a), do: 32
  defp d(?b), do: 33
  defp d(?c), do: 34
  defp d(?d), do: 35
  defp d(?e), do: 36
  defp d(?f), do: 37
  defp d(?g), do: 38
  defp d(?h), do: 39
  defp d(?i), do: 40
  defp d(?j), do: 41
  defp d(?k), do: 42
  defp d(?m), do: 43
  defp d(?n), do: 44
  defp d(?o), do: 45
  defp d(?p), do: 46
  defp d(?q), do: 47
  defp d(?r), do: 48
  defp d(?s), do: 49
  defp d(?t), do: 50
  defp d(?u), do: 51
  defp d(?v), do: 52
  defp d(?w), do: 53
  defp d(?x), do: 54
  defp d(?y), do: 55
  defp d(?z), do: 56
  defp d(_), do: throw(:error)

  @compile {:inline, v: 1}

  defp v(?0), do: true
  defp v(?1), do: true
  defp v(?2), do: true
  defp v(?3), do: true
  defp v(?4), do: true
  defp v(?5), do: true
  defp v(?6), do: true
  defp v(?7), do: true
  defp v(?8), do: true
  defp v(?9), do: true
  defp v(?A), do: true
  defp v(?B), do: true
  defp v(?C), do: true
  defp v(?D), do: true
  defp v(?E), do: true
  defp v(?F), do: true
  defp v(?a), do: true
  defp v(?b), do: true
  defp v(?c), do: true
  defp v(?d), do: true
  defp v(?e), do: true
  defp v(?f), do: true
  defp v(_), do: false
end
