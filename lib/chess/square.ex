
defmodule Chess.Square.Sees do
  defstruct up: [],
            down: [],
            left: [],
            right: [],
            up_right: [],
            up_left: [],
            down_left: [],
            down_right: [],
            knight: [],
            all: MapSet.new()
end
defmodule Chess.Square do
  alias Chess.Square.Sees


  defstruct column: nil,
            row:    nil,
            loc:    {},
            piece: nil,
            sees: %Sees{}

end
