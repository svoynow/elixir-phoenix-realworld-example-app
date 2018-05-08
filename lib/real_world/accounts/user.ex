defmodule RealWorld.Accounts.User do
  @moduledoc """
  The User model.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias RealWorld.Accounts.User

  @required_fields ~w(email username password)a
  @optional_fields ~w(bio image)a

  schema "users" do
    field(:email, :string, unique: true)
    field(:password, :string)
    field(:username, :string, unique: true)
    field(:bio, :string)
    field(:image, :string)
    field(:token, :string, virtual: true)

    has_many(:articles, RealWorld.Blog.Article)
    has_many(:comments, RealWorld.Blog.Comment)
    has_many(:followers, RealWorld.Accounts.UserFollower, foreign_key: :followee_id)
    has_many(:followees, RealWorld.Accounts.UserFollower, foreign_key: :user_id)

    timestamps(inserted_at: :created_at)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:username, name: :users_username_index)
    |> unique_constraint(:email)
  end

  def add_token(%User{} = user, token) do
    %{user | token: token}
  end

  def add_token(%User{} = user) do
    {:ok, token, _} = RealWorldWeb.Guardian.encode_and_sign(user, %{}, token_type: :token)
    add_token(user, token)
  end
end
