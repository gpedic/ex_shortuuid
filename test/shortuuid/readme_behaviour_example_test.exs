defmodule ShortUUID.ReadmeBehaviourExampleTest do
  @moduledoc """
  Compiles the hand-written `ShortUUID.Behaviour` example from README.md
  exactly as shown there, and checks it behaves as the README describes.
  """
  use ExUnit.Case, async: true

  @readme Path.expand("../../README.md", __DIR__)
  @external_resource @readme

  @example (case Regex.run(
                   ~r/```elixir\n(defmodule MyApp\.UserID do\n.*?\nend)\n```/s,
                   File.read!(@readme)
                 ) do
              [_, code] -> code
              nil -> raise "MyApp.UserID example not found in README.md"
            end)

  Code.compile_string(@example, @readme)

  alias MyApp.UserID

  @uuid "550e8400-e29b-41d4-a716-446655440000"
  @short "H9cNmGXLEc8NWcZzSThA9S"

  test "implements ShortUUID.Behaviour" do
    assert ShortUUID.Behaviour in Keyword.get(UserID.__info__(:attributes), :behaviour, [])
  end

  test "encodes with the prefix and round-trips" do
    assert UserID.encode(@uuid) == {:ok, "usr_" <> @short}
    assert UserID.encode!(@uuid) == "usr_" <> @short
    assert UserID.decode("usr_" <> @short) == {:ok, @uuid}
    assert UserID.decode!("usr_" <> @short) == @uuid
  end

  test "accepts every UUID format ShortUUID accepts" do
    for input <- [
          String.upcase(@uuid),
          String.replace(@uuid, "-", ""),
          "{#{@uuid}}",
          "urn:uuid:#{@uuid}"
        ] do
      assert UserID.encode(input) == {:ok, "usr_" <> @short}
    end
  end

  test "round-trips random UUIDs" do
    for _ <- 1..200 do
      <<a::32, b::16, c::16, d::16, e::48>> = :crypto.strong_rand_bytes(16)

      uuid =
        :io_lib.format("~8.16.0b-~4.16.0b-~4.16.0b-~4.16.0b-~12.16.0b", [a, b, c, d, e])
        |> IO.iodata_to_binary()

      assert {:ok, id} = UserID.encode(uuid)
      assert UserID.decode(id) == {:ok, uuid}
      assert UserID.encode!(UserID.decode!(id)) == id
    end
  end

  test "rejects anything but the one ID for each UUID" do
    for input <- [
          "org_" <> @short,
          @short,
          "usr_",
          "usr_garbage",
          "usr_" <> @uuid,
          "usr_" <> String.upcase(@uuid),
          "usr_" <> String.replace(@uuid, "-", ""),
          "USR_" <> @short,
          "usr_h9CnMgxlEC8nwCzZsTHa9s",
          "usr_" <> @short <> "2",
          " usr_" <> @short,
          "usr_" <> <<0xFF>>,
          "",
          nil,
          123,
          :usr,
          ~c"usr_" ++ String.to_charlist(@short)
        ] do
      assert {:error, _} = UserID.decode(input), "expected #{inspect(input)} to be rejected"
    end
  end

  test "rejects invalid UUIDs when encoding" do
    for input <- ["not-a-uuid", "", nil, 123, @short, "usr_" <> @short] do
      assert {:error, _} = UserID.encode(input), "expected #{inspect(input)} to be rejected"
    end
  end

  test "bang variants raise ArgumentError" do
    assert_raise ArgumentError, fn -> UserID.decode!("org_" <> @short) end
    assert_raise ArgumentError, fn -> UserID.decode!("usr_garbage") end
    assert_raise ArgumentError, fn -> UserID.decode!(nil) end
    assert_raise ArgumentError, fn -> UserID.encode!("not-a-uuid") end
    assert_raise ArgumentError, fn -> UserID.encode!(nil) end
  end
end
