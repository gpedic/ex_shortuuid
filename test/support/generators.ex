defmodule ShortUUID.TestGenerators do
  @moduledoc false
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

  def valid_emoji_alphabet_generator do
    # Creates a list of emoji characters
    all_chars =
      Enum.to_list(0x1F300..0x1F3FF) # Misc Symbols & Pictographs
      |> Kernel.++(Enum.to_list(0x1F400..0x1F4FF)) # Pictographs Extended
      |> Kernel.++(Enum.to_list(0x1F500..0x1F5FF)) # Transport & Map Symbols
      |> Kernel.++(Enum.to_list(0x1F600..0x1F64F)) # Emoticons
      |> Kernel.++(Enum.to_list(0x1F680..0x1F6FF)) # Transport & Map Symbols Extended
      |> Kernel.++(Enum.to_list(0x1F900..0x1F9FF)) # Supplemental Symbols & Pictographs
      |> List.to_string()
      |> String.graphemes()
      |> Enum.uniq()

    generate_alphabet(all_chars)
  end

  def valid_alphanumeric_alphabet_generator do
    # Creates a list of alphanumeric characters
    all_chars =
      ?0..?9
      |> Enum.to_list()
      |> Kernel.++(Enum.to_list(?A..?Z))
      |> Kernel.++(Enum.to_list(?a..?z))
      |> List.to_string()
      |> String.graphemes()

    generate_alphabet(all_chars)
  end

  def valid_url_safe_alphabet_generator do
    # Creates a list of URL-safe characters
    all_chars =
      ?0..?9
      |> Enum.to_list()
      |> Kernel.++(Enum.to_list(?A..?Z))
      |> Kernel.++(Enum.to_list(?a..?z))
      |> Kernel.++(String.to_charlist("-._~+/")) # URL-safe special chars
      |> List.to_string()
      |> String.graphemes()

    generate_alphabet(all_chars)
  end

  defp generate_alphabet(source_chars) do
    StreamData.bind(StreamData.integer(16..256), fn length ->
      subset =
        source_chars
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
