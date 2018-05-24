defmodule RealWorld.Accounts.Users do
  @moduledoc """
  The boundary for the Users system
  """

  alias RealWorld.Repo
  alias RealWorld.Accounts.User
  alias RealWorld.Accounts.UserFollower
  alias RealWorld.Blog.Favorite

  import Ecto.Query

  def get_user!(id), do: Repo.get!(User, id)
  def get_by_username(username), do: Repo.get_by(User, username: username)

  def update_user(user, attrs) do
    case user
         |> User.changeset(attrs)
         |> Repo.update() do
      {:ok, user} -> {:ok, User.add_token(user)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def follow_by_name(user, followee_name) do
    case get_by_username(followee_name) do
      nil ->
        {:error, ["user not found"]}

      followee ->
        case follow(user, followee) do
          {:error, err} -> {:error, err}
          _ -> followee
        end
    end
  end

  def follow(user, followee) do
    %UserFollower{}
    |> UserFollower.changeset(%{user_id: user.id, followee_id: followee.id})
    |> Repo.insert()
  end

  def unfollow_by_name(user, followee_name) do
    case get_by_username(followee_name) do
      nil ->
        {:error, ["user not found"]}

      followee ->
        case unfollow(user, followee) do
          {:error, err} -> {:error, err}
          _ -> followee
        end
    end
  end

  def unfollow(user, followee) do
    relation =
      UserFollower
      |> Repo.get_by(user_id: user.id, followee_id: followee.id)

    case relation do
      nil ->
        false

      relation ->
        Repo.delete(relation)
    end
  end

  def is_following?(user_id, followee_id) do
    UserFollower |> Repo.get_by(user_id: user_id, followee_id: followee_id) != nil
  end

  def data() do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(UserFollower, %{current_user: nil}) do
    UserFollower
  end

  def query(UserFollower, %{current_user: user}) do
    UserFollower
    |> where([..., uf], uf.user_id == ^user.id)
  end

  def query(Article, %{user: user}) do
    Article
    |> join(:inner, [..., a], f in Favorite, a.id == f.article_id)
    |> where([..., f], f.user_id == ^user.id)
  end

  def query(queryable, _args) do
    queryable
  end
end
