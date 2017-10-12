defmodule MockBehaviour do
  @moduledoc """
  MockBehaviour helps you maintain mocks for your behaviours.

  This code is inspired by the pattern shown in Jose Valim's article on mocks ( http://blog.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/ ).

  Assume the following behaviour:

  ```elixir
  defmodule TwitterContract do
    @callback tweets(user_id :: String.t) :: [map()]
  end

  defmodule TwitterContractHttp do
    @behaviour TwitterContract
    def tweets(user_id), do: # call to Twitter, return desired tweets
  end
  ```

  At this point, your code might be using `TwitterContractHttp` and you are now inextricably bound to an external service.

  Not so! You can create an API to get to your external services, and use mocks at that level. All you have to do is this:

  ```elixir
  defmodule Contracts do
    @behaviour TwitterContract
    @twitter Application.get_env(:app, :contracts)[:twitter_module]

    def tweets(user_id), do: @twitter.tweets(user_id)
  end
  ```

  And you can configure your system like so:

  ```elixir
  # dev
  config :app, :contracts, [
    twitter_module: TwitterContractHttp
  ]

  # test
  config :app, :contracts, [
    twitter_module: TwitterContractMock
  ]
  ```

  At this point, to reap the rewards from this package, all you have to do is:

  ```elixir
  defmodule TwitterContractMock do
    use MockBehaviour, behaviour: TwitterContract
  end
  ```

  This will generate the following code:

  ```elixir
  defmodule TwitterContractMock do
    use GenServer
    def start_link(state) do
      GenServer.start_link(__MODULE__, state, name: __MODULE__)
    end

    def tweets(user_id) do
      GenServer.call(__MODULE__, {:tweets, user_id})
    end

    def handle_call({:tweets, user_id}, _from, state) do
      response = state.tweets.(user_id)
      {:reply, response, state}
    end
  end
  ```

  From there, in your tests you can simply define and use an anonymous function:

  ```elixir
  tweets = fn(x) -> [%{tweet: "This package is such a timesaver", user: "Trevoke" }]

  TwitterContractMock.start_link(%{tweets: tweets})
  ```

  Enjoy your self-maintaining mocks!
  """
  defmacro __using__(behaviour: behaviour) do
    a = quote do
      @behaviour unquote(behaviour)
      use GenServer
      def start_link(state) do
        GenServer.start_link(__MODULE__, state, name: __MODULE__)
      end
    end
    x = Macro.expand(behaviour, __ENV__).behaviour_info(:callbacks)
    b = for {fname, arity} <- x do
      quote do
        MockBehaviour.handle_mock_call(unquote(fname), unquote(arity))
      end
    end
    [a, b]
  end

  defmacro handle_mock_call(x, y) when is_atom(x) and is_integer(y) do
    function_signature =
    (0..y)
    |> Enum.to_list
    |> List.delete_at(0)
    |> Enum.map(fn name ->
      {String.to_atom(Integer.to_string(name)), [], __MODULE__}
    end)
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
