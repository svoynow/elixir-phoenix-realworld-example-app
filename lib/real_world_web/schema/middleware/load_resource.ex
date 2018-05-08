defmodule RealWorldWeb.Schema.Middleware.LoadResource do
  alias Absinthe.Resolution
  @behaviour Absinthe.Middleware

  def call(resolution, %{arg: arg, contextKey: key, dataSource: source, error: error}) do
    with argument <- Map.get(resolution.arguments, arg),
         {:ok, data} <- source.(argument) do
      %{resolution | context: Map.put(resolution.context, key, data)}
    else
      _ ->
        Resolution.put_result(resolution, {:error, error})
    end
  end
end
