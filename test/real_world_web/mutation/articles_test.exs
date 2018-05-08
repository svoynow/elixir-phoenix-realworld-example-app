defmodule RealWorld.Mutation.ArticlesTest do
  use RealWorldWeb.ConnCase
  import RealWorld.Factory
  import RealWorldWeb.GraphqlFragments

  setup do
    user = insert(:user)
    other_user = insert(:user)
    {:ok, user: user, other_user: other_user}
  end

  @new_article_mutation """
    mutation PostArticle($article: ArticleCreate!) {
      article(article: $article) {
        result {
          author {
            username
          }
          title
          body  
          slug        
        }
        successful 
        messages {
          code
          field
          message
        }
      }
    }
    #{errors_on("ArticleResult")}
  """

  @update_article_mutation """
    mutation UpdateArticle($slug: String!, $update: ArticleUpdate!) {
      updateArticle(slug: $slug, update: $update) {
        result {
          title
          body        
        }
        ...errorFields
      }
    }
    #{errors_on("ArticleResult")}
  """

  @delete_article_mutation """
    mutation DeleteArticle($slug: String!) {
      deleteArticle(slug: $slug) {
        result {
          success
        }
        ...errorFields
      }
    }
    #{errors_on("DeletionResult")}
  """

  @favorite_mutation """
    mutation Favorite($slug: String!) {
      favorite(slug: $slug) {
        result {
          title
          body
        }
        ...errorFields
      }
    }
    #{errors_on("ArticleResult")}
  """

  @unfavorite_mutation """
    mutation Unfavorite($slug: String!) {
      unfavorite(slug: $slug) {
        result {
          title
          body
        }
        ...errorFields
      }
    }
    #{errors_on("ArticleResult")}
  """

  @add_comment_mutation """
    mutation AddComment($slug: String!, $comment: CommentCreate!) {
      comment(slug: $slug, comment: $comment) {
        result {
          body
        }
        ...errorFields
      }
    }
    #{errors_on("CommentResult")}
  """

  @delete_comment_mutation """
    mutation DeleteComment($slug: String!, $id: Int!) {
      deleteComment(slug: $slug, id: $id) {
        result {
          success
        }
        ...errorFields
      }
    }
    #{errors_on("DeletionResult")}
  """

  test "post article", %{conn: conn, user: user} do
    params =
      :article
      |> params_for()
      |> Map.take([:title, :description, :body])

    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(query: @new_article_mutation, variables: %{article: params})
      |> Map.fetch!("data")
      |> Map.fetch!("article")
      |> Map.fetch!("result")

    assert Map.fetch!(response, "title") == params[:title]
  end

  test "must be logged in to post article", %{conn: conn} do
    params =
      :article
      |> params_for()
      |> Map.take([:title, :description, :body])

    response =
      conn
      |> graphql_query(query: @new_article_mutation, variables: %{article: params})

    assert response
           |> Map.fetch!("data")
           |> Map.fetch!("article") == nil

    assert response
           |> Map.fetch!("errors")
           |> List.first()
           |> Map.fetch!("message") == "unauthorized"
  end

  test "update article", %{conn: conn, user: user} do
    article = insert(:article, author: user)

    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(
        query: @update_article_mutation,
        variables: %{slug: article.slug, update: %{body: "new stuff"}}
      )
      |> Map.fetch!("data")
      |> Map.fetch!("updateArticle")
      |> Map.fetch!("result")

    assert Map.fetch!(response, "body") == "new stuff"
  end

  test "must be article author to update article", %{
    conn: conn,
    user: user,
    other_user: other_user
  } do
    article = insert(:article, author: other_user)

    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(
        query: @update_article_mutation,
        variables: %{slug: article.slug, update: %{body: "new stuff"}}
      )

    assert response
           |> Map.fetch!("errors")
           |> List.first()
           |> Map.fetch!("message") == "unauthorized"

    assert response
           |> Map.fetch!("data")
           |> Map.fetch!("updateArticle") == nil
  end

  test "delete article", %{conn: conn, user: user} do
    article = insert(:article, author: user)

    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(
        query: @delete_article_mutation,
        variables: %{slug: article.slug}
      )
      |> Map.fetch!("data")
      |> Map.fetch!("deleteArticle")
      |> Map.fetch!("result")
      |> Map.fetch!("success")

    assert response == true
  end

  test "must be article author to delete article", %{
    conn: conn,
    user: user
  } do
    article = insert(:article)

    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(
        query: @delete_article_mutation,
        variables: %{slug: article.slug}
      )

    assert response
           |> Map.fetch!("errors")
           |> List.first()
           |> Map.fetch!("message") == "unauthorized"

    assert response
           |> Map.fetch!("data")
           |> Map.fetch!("deleteArticle") == nil
  end

  test "favorite article", %{conn: conn, user: user} do
    article = insert(:article)

    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(query: @favorite_mutation, variables: %{slug: article.slug})
      |> Map.fetch!("data")
      |> Map.fetch!("favorite")
      |> Map.fetch!("result")

    assert Map.fetch!(response, "title") == article.title
  end

  test "must be logged in to favorite article", %{conn: conn} do
    article = insert(:article)

    response =
      conn
      |> graphql_query(query: @favorite_mutation, variables: %{slug: article.slug})

    assert response
           |> Map.fetch!("errors")
           |> List.first()
           |> Map.fetch!("message") == "unauthorized"

    assert response
           |> Map.fetch!("data")
           |> Map.fetch!("favorite") == nil
  end

  test "unfavorite article", %{conn: conn, user: user} do
    article = insert(:article)
    _favorite = insert(:favorite, user: user, article: article)

    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(query: @unfavorite_mutation, variables: %{slug: article.slug})
      |> Map.fetch!("data")
      |> Map.fetch!("unfavorite")
      |> Map.fetch!("result")

    assert Map.fetch!(response, "title") == article.title
  end

  test "add comment", %{conn: conn, user: user} do
    article = insert(:article, author: user)
    _comment = insert(:comment, article: article)

    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(
        query: @add_comment_mutation,
        variables: %{
          slug: article.slug,
          comment: %{body: "I disagree"}
        }
      )
      |> Map.fetch!("data")
      |> Map.fetch!("comment")
      |> Map.fetch!("result")

    assert Enum.count(response) == 2

    assert response
           |> List.last()
           |> Map.fetch!("body") == "I disagree"
  end

  test "must be logged in to comment", %{conn: conn} do
    article = insert(:article)

    response =
      conn
      |> graphql_query(
        query: @add_comment_mutation,
        variables: %{
          slug: article.slug,
          comment: %{body: "No!"}
        }
      )

    assert response
           |> Map.fetch!("errors")
           |> List.first()
           |> Map.fetch!("message") == "unauthorized"

    assert response
           |> Map.fetch!("data")
           |> Map.fetch!("comment") == nil
  end

  test "trying to comment on non-existent article returns an error", %{conn: conn, user: user} do
    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(
        query: @add_comment_mutation,
        variables: %{
          slug: "no-such-article-nohow-noway",
          comment: %{body: "No!"}
        }
      )

    assert response
           |> Map.fetch!("errors")
           |> List.first()
           |> Map.fetch!("message") == "Article not found"

    assert response
           |> Map.fetch!("data")
           |> Map.fetch!("comment") == nil
  end

  test "delete comment", %{conn: conn, user: user} do
    article = insert(:article)
    comment = insert(:comment, article: article, author: user)

    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(
        query: @delete_comment_mutation,
        variables: %{slug: article.slug, id: comment.id}
      )
      |> Map.fetch!("data")
      |> Map.fetch!("deleteComment")
      |> Map.fetch!("result")
      |> Map.fetch!("success")

    assert response == true
  end

  test "must be be comment author to delete comment", %{
    conn: conn,
    user: user,
    other_user: other_user
  } do
    article = insert(:article)
    comment = insert(:comment, article: article, author: other_user)

    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(
        query: @delete_comment_mutation,
        variables: %{slug: article.slug, id: comment.id}
      )

    assert response
           |> Map.fetch!("errors")
           |> List.first()
           |> Map.fetch!("message") == "unauthorized"

    assert response
           |> Map.fetch!("data")
           |> Map.fetch!("deleteComment") == nil
  end
end
