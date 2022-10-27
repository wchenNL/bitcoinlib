defmodule BitcoinLib.Key.HD.DerivationPath.Parser do
  @moduledoc """
  Single purpose module that aims to simplify DerivationPath by isolating string parsing business
  logic
  """

  alias BitcoinLib.Key.HD.DerivationPath
  alias BitcoinLib.Key.HD.DerivationPath.{Level}
  alias BitcoinLib.Key.HD.DerivationPath.Parser.{Purpose, CoinType, Change}

  @invalid_atom :invalid

  @doc """
  Single purpose function that's being called by DerivationPath.parse/1, returning a DerivationPath
  out of a string if the tuple starts by :ok

  ## Examples
      iex> "m/44'/0'/0'/1/0"
      ...> |> BitcoinLib.Key.HD.DerivationPath.Parser.parse_valid_derivation_path
      {
        :ok,
        %BitcoinLib.Key.HD.DerivationPath{
          type: :private,
          purpose: :bip44,
          coin_type: :bitcoin,
          account: %BitcoinLib.Key.HD.DerivationPath.Level{hardened?: true, value: 0},
          change: :change_chain,
          address_index: %BitcoinLib.Key.HD.DerivationPath.Level{hardened?: false, value: 0}
        }
      }
  """
  @spec parse_valid_derivation_path(binary()) ::
          {:ok, %DerivationPath{}} | {:error, binary()}
  def parse_valid_derivation_path(derivation_path) do
    case validate(derivation_path) do
      {:ok, derivation_path} ->
        derivation_path
        |> split_path
        |> extract_string_values
        |> parse_values
        |> assign_keys
        |> create_hash(derivation_path)
        |> parse_purpose
        |> parse_coin_type
        |> parse_change
        |> add_status_code

      {:error, message} ->
        {:error, message}
    end
  end

  defp validate(derivation_path) do
    trimmed_path =
      derivation_path
      |> String.replace(" ", "")

    case Regex.match?(~r/^(m|M)((\/(\d+\'?)*){0,5})$/, trimmed_path) do
      true -> {:ok, trimmed_path}
      false -> {:error, "Invalid derivation path"}
    end
  end

  defp extract_type("m" <> _rest), do: :private
  defp extract_type("M" <> _rest), do: :public

  defp split_path(derivation_path) do
    Regex.scan(~r/\/\s*(\d+\'?)/, derivation_path)
  end

  defp extract_string_values(split_path) do
    split_path
    |> Enum.map(fn [_, value] ->
      Regex.named_captures(~r/(?<value_string>\d+)(?<has_quote>\'?)/, value)
    end)
  end

  defp parse_values(string_values) do
    string_values
    |> Enum.map(fn %{"has_quote" => has_quote, "value_string" => value_string} ->
      {value, _} = Integer.parse(value_string)

      %Level{
        value: value,
        hardened?: has_quote == "'"
      }
    end)
  end

  defp assign_keys(parsed_values) do
    parsed_values
    |> Enum.zip_with(
      ["purpose", "coin_type", "account", "change", "address_index"],
      fn value, title -> {String.to_atom(title), value} end
    )
  end

  defp create_hash(keys_and_values, derivation_path) do
    type = extract_type(derivation_path)

    keys_and_values
    |> Enum.reduce(%DerivationPath{type: type}, fn {key, value}, acc ->
      acc
      |> Map.put(key, value)
    end)
  end

  defp parse_purpose(%DerivationPath{purpose: nil} = hash), do: hash

  defp parse_purpose(%DerivationPath{purpose: %{hardened?: true, value: value}} = hash) do
    hash
    |> Map.put(
      :purpose,
      Purpose.parse(value)
    )
  end

  defp parse_coin_type(%DerivationPath{coin_type: nil} = hash), do: hash

  defp parse_coin_type(%DerivationPath{coin_type: %{hardened?: true, value: value}} = hash) do
    hash
    |> Map.put(
      :coin_type,
      CoinType.parse(value)
    )
  end

  defp parse_change(%DerivationPath{change: nil} = hash), do: hash

  defp parse_change(%DerivationPath{change: %{hardened?: false, value: value}} = hash) do
    hash
    |> Map.put(
      :change,
      Change.parse(value)
    )
  end

  defp add_status_code(%{purpose: @invalid_atom}), do: {:error, "Invalid purpose"}
  defp add_status_code(%{coin_type: @invalid_atom}), do: {:error, "Invalid coin type"}
  defp add_status_code(%{change: @invalid_atom}), do: {:error, "Invalid change chain"}
  defp add_status_code(result), do: {:ok, result}
end
