defmodule RealWorld.Query.ArticlesTest do
  use RealWorldWeb.ConnCase

  import RealWorld.Factory

  setup do
    alice = insert(:user, %{username: "alice"})
    bob = insert(:user, %{username: "bob"})
    carol = insert(:user, %{username: "carol"})
    by_alice = insert(:article, %{author: alice, tag_list: ["a"]})
    by_bob = insert(:article, %{author: bob, tag_list: ["b"]})
    by_carol = insert(:article, %{author: carol, tag_list: ["c"]})
    insert(:favorite, %{user: alice, article: by_bob})
    insert(:favorite, %{user: alice, article: by_carol})
    insert(:follow, %{user_id: alice.id, followee_id: bob.id})

    users = %{
      alice: alice,
      bob: bob,
      carol: carol
    }

    articles = %{
      by_alice: by_alice,
      by_bob: by_bob,
      by_carol: by_carol
    }

    {:ok, users: users, articles: articles}
  end

  @articles_query """
    query Articles($tag: String, $author: String, $favorited: String, $limit: Int, $offset: Int) {
      articles(tag: $tag, author: $author, favorited: $favorited, limit: $limit, offset: $offset) {
        title
        author {
          username
        }
      }
    }
  """

  @feed_query """
    query Feed {
      feed {
        title
        author {
          username
        }
      }
    }
  """

  @article_query """
    query Article($slug: String!) {
      article(slug: $slug) {
        slug
        title
      }
    }
  """

  @comments_query """
    query Comments($slug: String!) {
      comments(slug: $slug) {
        body
      }
    }
  """

  @tags_query """
    query Tags {
      tags 
    }
  """

  test "non-logged-in user can get articles", %{conn: conn, articles: articles} do
    response = graphql_query(conn, query: @articles_query)
    assert Enum.count(response["data"]["articles"]) == Enum.count(articles)
  end

  test "filter articles by tag", %{conn: conn} do
    filtered_count =
      conn
      |> graphql_query(query: @articles_query, variables: %{tag: "c"})
      |> Map.fetch!("data")
      |> Map.fetch!("articles")
      |> Enum.count()

    assert filtered_count == 1
  end

  test "filter articles by author", %{conn: conn} do
    filtered =
      conn
      |> graphql_query(query: @articles_query, variables: %{author: "alice"})
      |> Map.fetch!("data")
      |> Map.fetch!("articles")

    assert Enum.count(filtered) == 1

    assert filtered
           |> List.first()
           |> Map.fetch!("author")
           |> Map.fetch!("username") == "alice"
  end

  test "filter articles by favorited", %{conn: conn} do
    filtered_count =
      conn
      |> graphql_query(query: @articles_query, variables: %{favorited: "alice"})
      |> Map.fetch!("data")
      |> Map.fetch!("articles")
      |> Enum.count()

    assert filtered_count == 2
  end

  test "combine filters", %{conn: conn, articles: %{by_bob: by_bob}} do
    filtered =
      conn
      |> graphql_query(query: @articles_query, variables: %{author: "bob", favorited: "alice"})
      |> Map.fetch!("data")
      |> Map.fetch!("articles")

    assert Enum.count(filtered) == 1

    assert filtered
           |> List.first()
           |> Map.fetch!("title") == by_bob.title
  end

  test "articles paginated", %{conn: conn} do
    page_one =
      conn
      |> graphql_query(query: @articles_query, variables: %{limit: 2})
      |> Map.fetch!("data")
      |> Map.fetch!("articles")

    page_two =
      conn
      |> graphql_query(query: @articles_query, variables: %{limit: 2, offset: 2})
      |> Map.fetch!("data")
      |> Map.fetch!("articles")

    assert Enum.count(page_one) == 2
    assert Enum.count(page_two) == 1
  end

  test "non-logged-in user does not have a feed", %{conn: conn} do
    response = graphql_query(conn, query: @feed_query)

    assert Map.fetch!(response, "data") == nil

    assert response
           |> Map.fetch!("errors")
           |> Enum.map(fn x -> Map.fetch!(x, "message") end)
           |> Enum.member?("unauthorized")
  end

  test "feed", %{conn: conn, users: %{alice: alice}} do
    feed =
      conn
      |> authenticate_user(alice)
      |> graphql_query(query: @feed_query)
      |> Map.fetch!("data")
      |> Map.fetch!("feed")

    assert Enum.count(feed) == 1

    assert feed
           |> List.first()
           |> Map.fetch!("author")
           |> Map.fetch!("username") == "bob"
  end

  test "article by slug", %{conn: conn} do
    article = insert(:article, %{slug: "find-by-slug"})

    result =
      conn
      |> graphql_query(query: @article_query, variables: %{slug: article.slug})
      |> Map.fetch!("data")
      |> Map.fetch!("article")

    assert result["slug"] == article.slug
    assert result["title"] == article.title
  end

  test "comments", %{conn: conn} do
    article = insert(:article)
    Enum.each(1..5, fn _ -> insert(:comment, %{article: article}) end)

    comments =
      conn
      |> graphql_query(query: @comments_query, variables: %{slug: article.slug})
      |> Map.fetch!("data")
      |> Map.fetch!("comments")

    assert Enum.count(comments) == 5
  end

  test "tags", %{conn: conn} do
    tags =
      conn
      |> graphql_query(query: @tags_query)
      |> Map.fetch!("data")
      |> Map.fetch!("tags")

    assert Enum.sort(tags) == ["a", "b", "c"]
  end
end
