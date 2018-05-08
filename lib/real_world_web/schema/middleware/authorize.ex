defmodule RealWorldWeb.Schema.Middleware.Authorize do
  @behaviour Absinthe.Middleware

  def call(resolution, [_h | _t] = tests) do
    authorized =
      tests
      |> Enum.map(& &1.(resolution.context))
      |> Enum.all?()

    if authorized, do: resolution, else: unauthorized(resolution)
  end

  def call(resolution, nil), do: call(resolution, &logged_in?/1)

  def call(resolution, test), do: call(resolution, [test])

  def owns_article?(%{current_user: user, article: article}) do
    user.id == article.user_id
  end

  def owns_article?(%{current_user: nil}), do: false

  # fall through to other errors if any
  def owns_article?(_), do: true

  def owns_comment?(%{current_user: user, comment: comment}) do
    user.id == comment.user_id
  end

  def owns_comment?(%{current_user: nil}), do: false

  # fall through to other errors if any
  def owns_comment?(_), do: true

  def logged_in?(%{current_user: nil}), do: false
  def logged_in?(%{current_user: _user}), do: true
  def logged_in?(_), do: false

  defp unauthorized(res) do
    Absinthe.Resolution.put_result(res, {:error, "unauthorized"})
  end
end
