defmodule MockBehaviour do
  defmacro __using__(behaviour: behaviour) do
    quote do
      require unquote(__MODULE__)
      import unquote(__MODULE__)
    end
    x = Macro.expand(behaviour, __ENV__).behaviour_info(:callbacks)
    for {fname, arity} <- x do
      quote do
        MockBehaviour.handle_mock_call(unquote(fname), unquote(arity))
      end
    end
  end

  defmacro handle_mock_call(x, y) when is_atom(x) and is_integer(y) do
    function_signature = (1..y) |> Enum.to_list |> Enum.map(fn name -> {String.to_atom(Integer.to_string(name)), [], __MODULE__} end)
    code = {:{}, [], [x | function_signature] }
    quote do
      def unquote(x)(unquote_splicing(function_signature)) do
        GenServer.call(__MODULE__, unquote(code))
      end

      def handle_call(unquote(code), _from, state) do
        response = state.unquote(x).(unquote_splicing(function_signature))
        {:reply, response, state}
      end
    end
  end
end
