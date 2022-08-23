defmodule BitcoinLib.Script do
  alias BitcoinLib.Script.{Analyzer, Parser, Runner}

  @doc """
  Transforms a script in the bitstring form into a list of opcodes

  ## Examples
    iex> <<0x76a914fde0a08625e327ba400644ad62d5c571d2eec3de88ac::200>>
    ...> |> BitcoinLib.Script.parse()
    [
      %BitcoinLib.Script.Opcodes.Stack.Dup{},
      %BitcoinLib.Script.Opcodes.Crypto.Hash160{},
      %BitcoinLib.Script.Opcodes.Data{
        value: <<0xfde0a08625e327ba400644ad62d5c571d2eec3de::160>>
      },
      %BitcoinLib.Script.Opcodes.BitwiseLogic.EqualVerify{},
      %BitcoinLib.Script.Opcodes.Crypto.CheckSig{
        script: <<0x76a914fde0a08625e327ba400644ad62d5c571d2eec3de88ac::200>>
      }
    ]
  """
  @spec parse(bitstring()) :: list()
  def parse(script) when is_bitstring(script) do
    script
    |> Parser.parse()
  end

  @spec execute(bitstring(), list()) :: {:ok, boolean()} | {:error, binary()}
  def execute(script, stack) when is_bitstring(script) do
    script
    |> Parser.parse()
    |> Runner.execute(stack)
  end

  @spec identify(bitstring() | list()) :: :unknown | :p2pk | :p2pkh | :p2sh
  def identify(script) do
    script
    |> Analyzer.identify()
  end
end
