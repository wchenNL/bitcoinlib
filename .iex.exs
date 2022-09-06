alias BitcoinLib.Console
alias BitcoinLib.Crypto
alias BitcoinLib.Script
alias BitcoinLib.Transaction
alias BitcoinLib.Key.{Address, PrivateKey, PublicKey, PublicKeyHash}
alias BitcoinLib.Key.HD.{DerivationPath, Entropy, MnemonicSeed}

orange = IO.ANSI.color(5, 3, 1)

IO.puts orange <> "\nWelcome to the BitcoinLib REPL\n" <> IO.ANSI.reset

IEx.configure(
 default_prompt: [
   "\e[G",    # ANSI CHA, move cursor to column 1
    orange,
    "₿",
    :white,
    " ",
    :green,
    "%counter",
    :white,
    " >",
    :reset
  ]
  |> IO.ANSI.format
  |> IO.chardata_to_string
)

private_key =
  "12345612345612345612345612345612345612345612345612"
  |> Entropy.from_dice_rolls!()
  |> MnemonicSeed.wordlist_from_entropy()
  |> MnemonicSeed.to_seed()
  |> PrivateKey.from_seed()

public_key =
  private_key
  |> PublicKey.from_private_key()

ss_private_key =
  PrivateKey.from_mnemonic_phrase("rally celery split order almost twenty ignore record legend learn chaos decade")

ss_xpriv =
  ss_private_key
  # this child is: bip 44 bitcoin mainnet account 0 receiving index 0
  |> PrivateKey.from_derivation_path!("m/49'/0'/0'/0/0")
  |> PrivateKey.serialize()


blue_wallet_pub_key =
  ss_private_key
  |> PrivateKey.from_derivation_path!("m/84'/0'/0'")
  |> PublicKey.from_private_key()

blue_wallet_zpub =
  blue_wallet_pub_key
  |> PublicKey.serialize(:zpub)

blue_wallet_address_0_pub_key =
  blue_wallet_pub_key
  |> PublicKey.derive_child!(0)
  |> PublicKey.derive_child!(0)

blue_wallet_address_0 =
  blue_wallet_address_0_pub_key
  |> PublicKey.to_address(:p2sh)

p2pkh_testnet_address =
  <<0x93CE48570B55C42C2AF816AEABA06CFEE1224FAE::160>>
  |> Address.from_public_key_hash(:p2pkh, :testnet)

p2sh_testnet_address =
  <<0x93CE48570B55C42C2AF816AEABA06CFEE1224FAE::160>>
  |> Address.from_public_key_hash(:p2sh, :testnet)

defmodule X do
  def display_public_key_hash mnemonics, derivation_path do
    public_key_hash =
      mnemonics
      |> PrivateKey.from_mnemonic_phrase()
      |> PrivateKey.from_derivation_path!(derivation_path)
      |> PublicKey.from_private_key()
      |> PublicKeyHash.from_public_key()

    IO.puts "#{derivation_path} -> #{public_key_hash |> Binary.to_hex}"

    mnemonics
  end
end

mnemonics = "rally celery split order almost twenty ignore record legend learn chaos decade"

mnemonics
|> X.display_public_key_hash("m/44'/1'/0'/0/0")
|> X.display_public_key_hash("m/44'/1'/0'/0/1")
|> X.display_public_key_hash("m/44'/1'/0'/1/0")
|> X.display_public_key_hash("m/44'/1'/0'/1/1")
