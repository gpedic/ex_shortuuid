defmodule ShortUUID.TestGenerators do
  use ExUnitProperties

  # Generates a V4 UUID with a 50% chance of removing hyphens,
  # randomly applies downcasing, upcasing, or capitalization.
  def uuid_generator do
    StreamData.map(StreamData.constant(:ok), fn _ ->
      uuid = UUID.uuid4()

      uuid =
        case :rand.uniform(3) do
          1 -> uuid
          2 -> String.replace(uuid, "-", "")
          3 -> "{#{uuid}}"
        end

      case :rand.uniform(3) do
        1 -> String.downcase(uuid)
        2 -> String.upcase(uuid)
        3 -> String.capitalize(uuid)
      end
    end)
  end

  def valid_alphabet_generator do
    # Creates a list of all alphanumeric characters
    all_chars =
      ?0..?9
      |> Enum.to_list()
      |> Kernel.++(Enum.to_list(?A..?Z))
      |> Kernel.++(Enum.to_list(?a..?z))
      |> List.to_string()
      |> String.graphemes()

    # Add additional symbols that are supported
    all_chars = all_chars ++ ["+", "-", "_", "/"]

    # Shuffle them, and take a random length between
    # 16 and 64 to ensure at least 16 unique characters.
    # Use StreamData.bind to transform the random length
    # into a generator that returns a random subset
    # of characters joined into a string.
    StreamData.bind(StreamData.integer(16..64), fn length ->
      subset =
        all_chars
        |> Enum.shuffle()
        |> Enum.take(length)

      StreamData.constant(Enum.join(subset))
    end)
  end

  def invalid_uuid_generator do
    StreamData.one_of([
      StreamData.string(:alphanumeric, min_length: 1, max_length: 50),
      StreamData.binary(min_length: 1, max_length: 50),
      StreamData.integer(),
      StreamData.boolean(),
      StreamData.constant(nil)
    ])
  end

  def random_binary_uuid do
    StreamData.binary(length: 16)
  end
end
