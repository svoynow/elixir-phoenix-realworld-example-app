defmodule RealWorld.Schema.Helpers do
  use Absinthe.Schema.Notation

  def required_list(type) do
    non_null(list_of(non_null(type)))
  end
end
