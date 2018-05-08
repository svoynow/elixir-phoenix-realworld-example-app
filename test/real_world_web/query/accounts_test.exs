defmodule RealWorld.Query.AccountsTest do
  use RealWorldWeb.ConnCase
  import RealWorld.Factory

  setup do
    user = insert(:user)
    other_user = insert(:user)
    _follow = insert(:follow, user_id: user.id, followee_id: other_user.id)
    _article = insert(:article, author: user)
    {:ok, user: user, other_user: other_user}
  end

  @me_query """
    query {
      me {
        username
        bio
        following
        articles {
          title
        }
      }
    }
  """

  @profile_query """
    query Profile($username: String!) {
      profile (username: $username) {
        username
        bio
        following
        articles {
          title
        }
      }
    }
  """

  test "logged in user can retrieve own profile", %{conn: conn, user: user} do
    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(query: @me_query)

    data = response["data"]
    assert data["me"]["username"] == user.username
    assert Enum.count(data["me"]["articles"]) == 1
  end

  test "unauthorized user receives error", %{conn: conn} do
    response = graphql_query(conn, query: @me_query)
    errors = response["errors"]
    data = response["data"]
    assert data["me"] == nil
    assert [%{"message" => "unauthorized"}] = errors
  end

  test "non-logged-in user can get profile", %{conn: conn, user: user} do
    response = graphql_query(conn, query: @profile_query, variables: %{username: user.username})
    data = response["data"]
    assert data["profile"]["username"] == user.username
  end

  test "following defaults to false for non-logged-in user", %{conn: conn, user: user} do
    response = graphql_query(conn, query: @profile_query, variables: %{username: user.username})
    data = response["data"]
    assert data["profile"]["following"] == false
  end

  test "profile: following is true for users you are following", %{
    conn: conn,
    user: follower,
    other_user: followee
  } do
    response =
      conn
      |> authenticate_user(follower)
      |> graphql_query(query: @profile_query, variables: %{username: followee.username})

    data = response["data"]
    assert data["profile"]["following"] == true
  end

  test "profile: following is false for users you are not following", %{
    conn: conn,
    user: follower,
    other_user: followee
  } do
    response =
      conn
      |> authenticate_user(followee)
      |> graphql_query(query: @profile_query, variables: %{username: follower.username})

    data = response["data"]
    assert data["profile"]["following"] == false
  end
end
