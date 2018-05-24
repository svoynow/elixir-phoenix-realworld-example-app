defmodule RealWorldWeb.Resolvers.Accounts do
  alias RealWorld.Accounts.{Auth, Users}
  alias RealWorld.Blog.Article
  alias RealWorld.Accounts
  import Kronky.Payload
  import Absinthe.Resolution.Helpers, only: [on_load: 2]

  def login(_, %{email: _email, password: _password} = args, _) do
    case Auth.find_user_and_check_password(args) do
      {:ok, user} -> {:ok, user}
      error -> error
    end
  end

  def register(_, %{user: %{email: _email, username: _username, password: _password} = args}, _) do
    case Auth.register(args) do
      {:ok, user} -> {:ok, user}
      {:error, changeset} -> {:ok, changeset}
    end
  end

  def update(_, %{user: args}, %{context: %{current_user: user, token: _token}}) do
    case Users.update_user(user, args) do
      {:ok, user} -> {:ok, user}
      {:error, changeset} -> {:ok, changeset}
    end
  end

  def profile(_, %{username: username}, _) do
    case Users.get_by_username(username) do
      nil -> {:error, "No such user"}
      user -> {:ok, user}
    end
  end

  def me(_, _, %{context: %{current_user: user}}) do
    {:ok, user}
  end

  def me(_, _, _) do
    {:ok, nil}
  end

  def favorited_articles(user, _, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load_many(Accounts, {:favorited_articles, %{user: user}}, [user])
    |> on_load(fn loader ->
      {:ok,
       Dataloader.get(
         loader,
         Accounts,
         {:favorited_articles, %{user: user}},
         user
       )}
    end)
  end

  def following?(user, _, %{context: %{loader: loader, current_user: current_user}}) do
    loader
    |> Dataloader.load_many(Accounts, {:followers, %{current_user: current_user}}, [user])
    |> on_load(fn loader ->
      case Dataloader.get(
             loader,
             Accounts,
             {:followers, %{current_user: current_user}},
             user
           ) do
        [] -> {:ok, false}
        nil -> {:ok, false}
        _ -> {:ok, true}
      end
    end)
  end

  def following?(_, _, %{context: %{current_user: nil}}) do
    {:ok, false}
  end

  def follow(_, %{username: followee_name}, %{context: %{current_user: user}}) do
    case Users.follow_by_name(user, followee_name) do
      {:error, changeset} ->
        {:ok, error_payload(changeset)}

      followee ->
        {:ok, success_payload(followee)}
    end
  end

  def unfollow(_, %{username: followee_name}, %{context: %{current_user: user}}) do
    case Users.unfollow_by_name(user, followee_name) do
      {:error, changeset} -> {:ok, error_payload(changeset)}
      followee -> {:ok, success_payload(followee)}
    end
  end
end
