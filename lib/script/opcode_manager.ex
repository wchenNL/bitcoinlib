defmodule BitcoinLib.Script.OpcodeManager do
  alias BitcoinLib.Script.Opcodes.{BitwiseLogic, Constants, Crypto, Stack}

  @byte 8

  @zero Constants.Zero.v()
  @dup Stack.Dup.v()
  @equal BitwiseLogic.Equal.v()
  @equal_verify BitwiseLogic.EqualVerify.v()
  @hash160 Crypto.Hash160.v()
  @check_sig Crypto.CheckSig.v()

  alias BitcoinLib.Signing.Psbt.CompactInteger

  @doc """
  Extract the opcode on the top of the stack given as an argument
  """
  @spec extract_from_script(bitstring(), bitstring()) ::
          {:empty_script} | {:ok, %Stack.Dup{}, bitstring()} | {:error, binary()}
  def extract_from_script(<<>>, _whole_script), do: {:empty_script}

  def extract_from_script(<<@zero::8, remaining::bitstring>>, _whole_script) do
    {:opcode, %Constants.Zero{}, remaining}
  end

  def extract_from_script(<<@dup::8, remaining::bitstring>>, _whole_script) do
    {:opcode, %Stack.Dup{}, remaining}
  end

  def extract_from_script(<<@equal::8, remaining::bitstring>>, _whole_script) do
    {:opcode, %BitwiseLogic.Equal{}, remaining}
  end

  def extract_from_script(<<@equal_verify::8, remaining::bitstring>>, _whole_script) do
    {:opcode, %BitwiseLogic.EqualVerify{}, remaining}
  end

  def extract_from_script(<<@hash160::8, remaining::bitstring>>, _whole_script) do
    {:opcode, %Crypto.Hash160{}, remaining}
  end

  def extract_from_script(<<@check_sig::8, remaining::bitstring>>, whole_script) do
    {:opcode, %Crypto.CheckSig{script: whole_script}, remaining}
  end

  def extract_from_script(<<unknown_opcode::8, remaining::bitstring>> = script, _whole_script) do
    case unknown_opcode do
      opcode when opcode in 0x01..0x4B -> extract_and_return_data(script)
      _ -> {:error, "trying to extract an unknown upcode: #{unknown_opcode}", remaining}
    end
  end

  defp extract_and_return_data(script) do
    %CompactInteger{value: data_length, remaining: remaining} =
      CompactInteger.extract_from(script)

    data_length = data_length * @byte

    <<data::bitstring-size(data_length), remaining::bitstring>> = remaining

    {:data, data, remaining}
  end
end
