defmodule RealWorldWeb.Resolvers.Articles do
  alias RealWorld.Blog
  alias RealWorld.Blog.Article

  @defaults %{limit: 20, offset: 0}

  def articles(_, args, _) do
    args = Map.merge(@defaults, args)
    {:ok, Blog.filtered_articles(args)}
  end

  def feed(_, args, %{context: %{current_user: user}}) do
    args = Map.merge(@defaults, args)
    {:ok, Blog.feed(user, args)}
  end

  def article(_, %{slug: slug}, _) do
    case Blog.get_article_by_slug(slug) do
      nil -> {:error, "Not found"}
      article -> {:ok, article}
    end
  end

  def create(_, %{article: params}, %{context: %{current_user: user}}) do
    case Blog.create_article(Map.merge(params, %{user_id: user.id})) do
      {:ok, article} ->
        {:ok, article}

      {:error, changeset} ->
        {:ok, changeset}
    end
  end

  def update(_, %{update: update}, %{context: %{article: article}}) do
    case Blog.update_article(article, update) do
      {:ok, article} -> {:ok, article}
      {:error, changeset} -> {:ok, changeset}
    end
  end

  def delete(_, _args, %{context: %{article: article}}) do
    case Blog.delete_article(article) do
      {:ok, _article} -> {:ok, %{success: true}}
      {:error, changeset} -> {:ok, changeset}
    end
  end

  def favorite(_, _args, %{context: %{current_user: user, article: article}}) do
    result =
      with {:ok, _favorite} <- Blog.favorite(user, article),
           do: Blog.load_user_and_favorite(article, user)

    case result do
      %Article{} -> {:ok, result}
      {:error, changeset} -> {:ok, changeset}
    end
  end

  # TODO how to handle no such favorite
  def unfavorite(_, _args, %{context: %{current_user: user, article: article}}) do
    result =
      with {:ok, _favorite} <- Blog.unfavorite(user, article),
           do: Blog.load_user_and_favorite(article, user)

    case result do
      %Article{} -> {:ok, result}
      {:error, changeset} -> {:ok, changeset}
    end
  end
end
