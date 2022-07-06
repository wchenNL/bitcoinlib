defmodule BitcoinLib.Test.Integration.Bip84.Bech32AddressFromZpub do
  use ExUnit.Case, async: true

  alias BitcoinLib.Key.HD.{MnemonicSeed, ExtendedPublic, ExtendedPrivate}

  @doc """
  based on https://github.com/bitcoin/bips/blob/master/bip-0084.mediawiki#test-vectors
  """
  test "generate bech32 address from a mnemonic phrase" do
    private_key =
      "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
      |> MnemonicSeed.to_seed()
      |> ExtendedPrivate.from_seed()

    address =
      private_key
      |> ExtendedPrivate.from_derivation_path!("m/84'/0'/0'/0/0")
      |> ExtendedPublic.from_private_key()
      |> ExtendedPublic.to_address(:bech32)

    assert address == "bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu"
  end
end
