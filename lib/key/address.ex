defmodule BitcoinLib.Key.Address do
  @moduledoc """
  Bitcoin address management

  Inspired by https://learnmeabitcoin.com/technical/public-key-hash
  """

  alias BitcoinLib.Crypto

  @doc """
  Convert public key hash into a P2PKH Bitcoin address.

  Details can be found here: https://en.bitcoin.it/wiki/Technical_background_of_version_1_Bitcoin_addresses

  ## Examples
    iex> <<0x6ae201797de3fa7d1d95510f50c1a9c50ce4cc36::160>>
    ...> |> BitcoinLib.Key.Address.from_public_key_hash(:p2pkh)
    "1Ak9NVPmwCHEpsSWvM6cNRC7dsYniRmwMG"
  """
  @spec from_public_key_hash(binary(), :p2pkh | :p2sh, :mainnet | :testnet) :: bitstring()
  def from_public_key_hash(public_key_hash, address_type \\ :p2sh, network \\ :mainnet) do
    public_key_hash
    |> Binary.to_hex()
    |> prepend_prefix(address_type, network)
    |> Binary.from_hex()
    |> append_checksum
    |> Base58.encode()
  end

  @doc """
  Extracts the public key hash from an address, and make sure the checkum is ok

  ## Examples
    iex> address = "mwYKDe7uJcgqyVHJAPURddeZvM5zBVQj5L"
    ...> BitcoinLib.Key.Address.destructure(address)
    {:ok, <<0xafc3e518577316386188af748a816cd14ce333f2::160>>, :p2pkh, :testnet}
  """
  @spec destructure(binary()) :: {:ok, <<_::160>>, atom()} | {:error, binary()}
  def destructure(address) do
    <<prefix::8, public_key_hash::bitstring-160, checksum::bitstring-32>> =
      address
      |> Base58.decode()

    {address_type, network} = get_address_type_from_prefix(prefix)

    case test_checksum(prefix, public_key_hash, checksum) do
      {:ok} -> {:ok, public_key_hash, address_type, network}
      {:error, message} -> {:error, message}
    end
  end

  defp prepend_prefix(public_key_hash, address_type, network) do
    get_prefix(address_type, network) <> public_key_hash
  end

  defp append_checksum(public_key_hash) do
    checksum =
      public_key_hash
      |> Crypto.checksum()

    public_key_hash <> checksum
  end

  @spec test_checksum(integer(), bitstring(), bitstring()) :: {:ok} | {:error, binary()}
  defp test_checksum(prefix, public_key_hash, original_checksum) do
    calculated_checksum =
      <<prefix::8, public_key_hash::bitstring-160>>
      |> Crypto.checksum()

    case calculated_checksum do
      ^original_checksum -> {:ok}
      _ -> {:error, "checksums don't match"}
    end
  end

  # Here is a useful list of address prefixes
  # https://en.bitcoin.it/wiki/List_of_address_prefixes

  defp get_prefix(:p2pkh, :mainnet), do: "00"
  defp get_prefix(:p2sh, :mainnet), do: "05"
  defp get_prefix(:p2pkh, :testnet), do: "6F"
  defp get_prefix(:p2sh, :testnet), do: "C4"
  defp get_prefix(_, _), do: ""

  # example 17VZNX1SN5NtKa8UQFxwQbFeFc3iqRYhem
  defp get_address_type_from_prefix(0), do: {:p2pkh, :mainnet}

  # example 3EktnHQD7RiAE6uzMj2ZifT9YgRrkSgzQX
  defp get_address_type_from_prefix(5), do: {:p2sh, :mainnet}

  # example mipcBbFg9gMiCh81Kj8tqqdgoZub1ZJRfn
  defp get_address_type_from_prefix(111), do: {:p2pkh, :testnet}

  # example 2MzQwSSnBHWHqSAqtTVQ6v47XtaisrJa1Vc
  defp get_address_type_from_prefix(196), do: {:p2sh, :testnet}

  defp get_address_type_from_prefix(_), do: :unknown
end
