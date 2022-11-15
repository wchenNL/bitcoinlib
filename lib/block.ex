defmodule BitcoinLib.Block do
  @moduledoc """
  Represents a Bitcoin Block

  Based on https://learnmeabitcoin.com/technical/block-header
  """
  defstruct [:header, transactions: []]

  alias BitcoinLib.Block
  alias BitcoinLib.Block.Header

  @doc """
  Converts a hex binary into a %Block{}

  ## Examples
      Parse the genesis block

      iex> "0100000000000000000000000000000000000000000000000000000000000000000000003ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a29ab5f49ffff001d1dac2b7c0101000000010000000000000000000000000000000000000000000000000000000000000000ffffffff4d04ffff001d0104455468652054696d65732030332f4a616e2f32303039204368616e63656c6c6f72206f6e206272696e6b206f66207365636f6e64206261696c6f757420666f722062616e6b73ffffffff0100f2052a01000000434104678afdb0fe5548271967f1a67130b7105cd6a828e03909a67962e0ea1f61deb649f6bc3f4cef38c4f35504e51ec112de5c384df7ba0b8d578a4c702b6bf11d5fac00000000"
      ...> |> Binary.from_hex()
      ...> |> BitcoinLib.Block.parse()
      %BitcoinLib.Block{
        header: %BitcoinLib.Block.Header{
          version: 1,
          previous_block_hash: <<0::256>>,
          merkle_root_hash: <<0x4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b::256>>,
          time: ~U[2009-01-03 18:15:05Z],
          bits: 486604799,
          nonce: 2083236893
        },
        transactions: []
      }
  """
  @spec parse(binary()) :: {:ok, %Block{}} | {:error, binary()}
  def parse(<<header_data::bitstring-640, _transactions_data::bitstring>>) do
    header = Header.parse(header_data)

    %Block{
      header: header
    }
  end
end
