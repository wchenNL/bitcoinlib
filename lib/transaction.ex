defmodule BitcoinLib.Transaction do
  @moduledoc """
  Based on https://learnmeabitcoin.com/technical/transaction-data#fields
  """
  defstruct [:version, :inputs, :outputs, :locktime]

  alias BitcoinLib.Signing.Psbt.CompactInteger
  alias BitcoinLib.Transaction
  alias BitcoinLib.Transaction.{Input, Output}

  def decode(encoded_transaction) do
    %{version: version, inputs: inputs, outputs: outputs, locktime: locktime} =
      %{remaining: encoded_transaction}
      |> extract_version
      |> extract_input_count
      |> extract_inputs
      |> extract_output_count
      |> extract_outputs
      |> extract_locktime

    %Transaction{version: version, inputs: inputs, outputs: outputs, locktime: locktime}
  end

  defp extract_version(%{remaining: <<version::little-32, remaining::bitstring>>} = map) do
    %{map | remaining: remaining}
    |> Map.put(:version, version)
  end

  defp extract_input_count(%{remaining: remaining} = map) do
    %CompactInteger{value: input_count, remaining: remaining} =
      CompactInteger.extract_from(remaining, :big_endian)

    %{map | remaining: remaining}
    |> Map.put(:input_count, input_count)
  end

  defp extract_inputs(%{input_count: input_count, remaining: remaining} = map) do
    {inputs, remaining} =
      case input_count do
        0 ->
          {[], remaining}

        _ ->
          1..input_count
          |> Enum.reduce({[], remaining}, fn _nb, {inputs, remaining} ->
            {input, remaining} = Input.extract_from(remaining)

            {[input | inputs], remaining}
          end)
      end

    %{map | remaining: remaining}
    |> Map.put(:inputs, inputs)
  end

  defp extract_output_count(%{remaining: remaining} = map) do
    %CompactInteger{value: output_count, remaining: remaining} =
      CompactInteger.extract_from(remaining, :big_endian)

    %{map | remaining: remaining}
    |> Map.put(:output_count, output_count)
  end

  defp extract_outputs(%{output_count: output_count, remaining: remaining} = map) do
    {outputs, remaining} =
      1..output_count
      |> Enum.reduce({[], remaining}, fn _nb, {outputs, remaining} ->
        {output, remaining} = Output.extract_from(remaining)

        {[output | outputs], remaining}
      end)

    %{map | remaining: remaining}
    |> Map.put(:outputs, outputs)
  end

  defp extract_locktime(%{remaining: remaining} = map) do
    <<locktime::little-32, remaining::bitstring>> = remaining

    %{map | remaining: remaining}
    |> Map.put(:locktime, locktime)
  end
end