defmodule BitcoinLib.Script.Opcodes.Constants.Zero do
  @behaviour BitcoinLib.Script.Opcode

  defstruct type: BitcoinLib.Script.Opcodes.Constants.Zero

  alias BitcoinLib.Script.Opcodes.Constants.Zero

  @value 0x00

  def v do
    @value
  end

  def execute(%Zero{}, remaining) do
    {:ok, remaining}
  end
end