defmodule RealWorldWeb.Resolvers.Comments do
  alias RealWorld.Blog

  def create(_, %{comment: params}, %{context: %{current_user: user, article: article}}) do
    comment_params = Map.merge(params, %{user_id: user.id, article_id: article.id})

    case Blog.create_comment(comment_params) do
      {:ok, _comment} -> {:ok, Blog.list_comments(article)}
      {:error, changeset} -> {:ok, changeset}
    end
  end

  def delete(_, _, %{context: %{article: article, comment: comment}}) do
    case comment.article_id == article.id do
      true ->
        Blog.delete_comment(comment)
        {:ok, %{success: true}}

      _ ->
        {:ok, %{success: false}}
    end
  end

  def for_article(_, _args, %{context: %{article: article}}) do
    {:ok, Blog.list_comments(article)}
  end
end
