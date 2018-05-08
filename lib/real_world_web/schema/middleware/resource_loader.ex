defmodule RealWorldWeb.Schema.Middleware.ResourceLoader do
  alias Absinthe.Resolution
  @behaviour Absinthe.Middleware

  def call(resolution, %{func: func, key: key}) do
    case func.(resolution.context, resolution.arguments) do
      {:ok, data} ->
        %{resolution | context: Map.put(resolution.context, key, data)}

      {:error, error} ->
        Resolution.put_result(resolution, {:error, error})
    end
  end
end
