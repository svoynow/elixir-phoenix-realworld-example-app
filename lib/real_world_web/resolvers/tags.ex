defmodule RealWorldWeb.Resolvers.Tags do
  alias RealWorld.Blog

  def list(_, _, _) do
    {:ok, Blog.list_tags()}
  end
end
