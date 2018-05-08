defmodule RealWorldWeb.AuthHelper do
  def authenticate_user(conn, user) do
    token = RealWorld.Accounts.User.add_token(user).token
    Plug.Conn.put_req_header(conn, "authorization", "Token #{token}")
  end
end
