defmodule RealWorldWeb.Context do
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context)
  end

  defp build_context(conn) do
    %{
      token: RealWorldWeb.Guardian.Plug.current_token(conn),
      current_user: RealWorldWeb.Guardian.Plug.current_resource(conn)
    }
  end
end
