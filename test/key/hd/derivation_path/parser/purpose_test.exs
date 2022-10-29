defmodule BitcoinLib.Key.HD.DerivationPath.Parser.PurposeTest do
  use ExUnit.Case, async: true

  doctest BitcoinLib.Key.HD.DerivationPath.Parser.Purpose

  alias BitcoinLib.Key.HD.DerivationPath.Parser.Purpose

  test "derivation path extraction of an invalid purpose" do
    derivation_path = ["0", "1", "2", "3", "4"]

    {:error, message} =
      derivation_path
      |> Purpose.extract()

    assert message == "0 is not a valid purpose"
  end
end
