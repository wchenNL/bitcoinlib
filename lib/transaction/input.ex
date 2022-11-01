defmodule BitcoinLib.Transaction.Input do
  @moduledoc """
  Based on https://learnmeabitcoin.com/technical/input
  """

  defstruct [:txid, :vout, :script_sig, :sequence]

  @byte 8

  alias BitcoinLib.Crypto.Bitstring
  alias BitcoinLib.Transaction.Input
  alias BitcoinLib.Script
  alias BitcoinLib.Signing.Psbt.CompactInteger

  @doc """
  Extracts a transaction input from a bitstring

  ## Examples
      iex> <<0x7b1eabe0209b1fe794124575ef807057c77ada2138ae4fa8d6c4de0398a14f3f0000000000ffffffff01f0ca052a010000001976a914cbc20a7664f2f69e5355aa427045bc15e7c6c77288ac00000000::640>>
      ...> |> BitcoinLib.Transaction.Input.extract_from()
      {
        :ok,
        %BitcoinLib.Transaction.Input{
          txid: "3f4fa19803dec4d6a84fae3821da7ac7577080ef75451294e71f9b20e0ab1e7b",
          vout: 0,
          script_sig: [],
          sequence: 4294967295
        },
        <<0x01f0ca052a010000001976a914cbc20a7664f2f69e5355aa427045bc15e7c6c77288ac00000000::312>>
      }
  """
  @spec extract_from(binary()) :: {:ok, %Input{}, bitstring()} | {:error, binary()}
  def extract_from(<<little_txid::bitstring-256, vout::little-32, remaining::bitstring>>) do
    txid =
      little_txid
      |> Bitstring.reverse()
      |> Binary.to_hex()

    case extract_script_sig(remaining) do
      {:error, message} ->
        {:error, message}

      {:ok, script_sig, remaining} ->
        {sequence, remaining} = extract_sequence(remaining)

        {
          :ok,
          %Input{
            txid: txid,
            vout: vout,
            script_sig: script_sig,
            sequence: sequence
          },
          remaining
        }
    end
  end

  @doc """
  Encodes an input into a bitstring

  ## Examples
      iex> %BitcoinLib.Transaction.Input{
      ...>   sequence: 0xFFFFFFFF,
      ...>   txid: "5e2383defe7efcbdc9fdd6dba55da148b206617bbb49e6bb93fce7bfbb459d44",
      ...>   vout: 1
      ...> } |> BitcoinLib.Transaction.Input.encode()
      <<0x449d45bbbfe7fc93bbe649bb7b6106b248a15da5dbd6fdc9bdfc7efede83235e0100000000ffffffff::328>>
  """
  @spec encode(%Input{}) :: bitstring()
  def encode(%Input{} = input) do
    txid =
      input.txid
      |> Binary.from_hex()
      |> Bitstring.reverse()

    {script_size, script} =
      input.script_sig
      |> format_script_sig()

    <<txid::bitstring-256, input.vout::little-32, script_size::bitstring, script::bitstring,
      input.sequence::little-32>>
  end

  defp format_script_sig(nil), do: {<<0::8>>, <<>>}
  defp format_script_sig(script_sig) when is_list(script_sig), do: script_sig |> Script.encode()

  defp format_script_sig(script_sig) when is_binary(script_sig) do
    script_sig_bit_size = byte_size(script_sig)

    {<<script_sig_bit_size::8>>, script_sig}
  end

  defp extract_script_sig(remaining) do
    %CompactInteger{value: script_sig_size, remaining: remaining} =
      CompactInteger.extract_from(remaining)

    script_sig_bit_size = script_sig_size * @byte

    <<script_sig::bitstring-size(script_sig_bit_size), remaining::bitstring>> = remaining

    case Script.parse(script_sig) do
      {:ok, script_sig} -> {:ok, script_sig, remaining}
      {:error, message} -> {:error, message}
    end
  end

  defp extract_sequence(remaining) do
    <<sequence::little-32, remaining::bitstring>> = remaining

    {sequence, remaining}
  end
end
