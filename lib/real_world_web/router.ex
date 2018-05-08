defmodule RealWorldWeb.Router do
  use RealWorldWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
    plug(ProperCase.Plug.SnakeCaseParams)

    plug(
      Guardian.Plug.Pipeline,
      error_handler: RealWorldWeb.SessionController,
      module: RealWorldWeb.Guardian
    )

    plug(Guardian.Plug.VerifyHeader, realm: "Token")
    plug(Guardian.Plug.LoadResource, allow_blank: true)
    plug(RealWorldWeb.Context)
  end

  scope "/api" do
    pipe_through(:api)
    forward("/", Absinthe.Plug, schema: RealWorldWeb.Schema)
  end

  scope "/graphiql" do
    pipe_through(:api)

    forward(
      "/",
      Absinthe.Plug.GraphiQL,
      schema: RealWorldWeb.Schema,
      socket: RealWorldWeb.UserSocket
    )
  end
end
