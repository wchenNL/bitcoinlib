defmodule BitcoinLib.Transaction.SpecTest do
  use ExUnit.Case, async: true

  alias BitcoinLib.{Script, Transaction}
  alias BitcoinLib.Key.{PrivateKey, PublicKey}
  alias BitcoinLib.Key.HD.SeedPhrase

  doctest BitcoinLib.Transaction.Spec

  test "create a segwit transaction and decode it" do
    {:ok, encoded_transaction} = create_signed_transaction()
    {:ok, transaction, ""} = decode_transaction(encoded_transaction)

    assert transaction.segwit?
  end

  defp create_signed_transaction do
    {:ok, seed_phrase} =
      SeedPhrase.from_dice_rolls("12345612345612345612345612345612345612345612345612")

    master_private_key = PrivateKey.from_seed_phrase(seed_phrase)

    receive_private_key =
      master_private_key
      |> PrivateKey.from_derivation_path!("m/49'/1'/0'/0/0")

    transaction_id = "39efb7042d02341a0f6ecced6de32abedf4d78776e6a42d867550b2cebefa3fd"
    vout = 0
    script_pub_key = "a91451caa671181d8819ccff9b81ffeb8fdafd95f91f87"

    destination_amount = 1000
    change_amount = 1_228_523

    destination_public_key_hash =
      master_private_key
      |> PrivateKey.from_derivation_path!("m/49'/1'/0'/0/1")
      |> PublicKey.from_private_key()
      |> PublicKey.hash()

    change_public_key_hash =
      master_private_key
      |> PrivateKey.from_derivation_path!("m/49'/1'/0'/1/1")
      |> PublicKey.from_private_key()
      |> PublicKey.hash()

    %Transaction.Spec{}
    |> Transaction.Spec.add_input!(
      txid: transaction_id,
      vout: vout,
      redeem_script: script_pub_key
    )
    |> Transaction.Spec.add_output(
      Script.Types.P2sh.create(destination_public_key_hash),
      destination_amount
    )
    |> Transaction.Spec.add_output(
      Script.Types.P2sh.create(change_public_key_hash),
      change_amount
    )
    |> Transaction.Spec.sign_and_encode([receive_private_key])
  end

  defp decode_transaction(encoded_transaction) do
    encoded_transaction
    |> Binary.from_hex()
    |> Transaction.decode()
  end
end
