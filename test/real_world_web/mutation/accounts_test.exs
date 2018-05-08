defmodule RealWorld.Mutation.AccountsTest do
  use RealWorldWeb.ConnCase
  import RealWorld.Factory
  import RealWorldWeb.GraphqlFragments

  setup do
    # this user gets created a different way because we need a
    # real hashed password to test login
    {:ok, user} =
      params_for(:user, password: "password")
      |> RealWorld.Accounts.Auth.register()

    other_user = insert(:user)
    {:ok, user: user, other_user: other_user}
  end

  @register_mutation """
    mutation Register($user: UserCreate) {
      register(user: $user) {
        result {
          username
          email
          token
        }
        ...errorFields
      }
    }
    #{errors_on("UserResult")}
  """

  @login_mutation """
    mutation Login($email: String!, $password: String!) {
      login(email: $email, password: $password) {
        username
        email
        token
      }
    }
  """

  @update_me_mutation """
    mutation UpdateMe($user: UserCreate) {
      updateMe(user: $user) {
        result {
          username
          email
          token
        }
        ...errorFields
      }
    }
    #{errors_on("UserResult")}
  """

  @follow_mutation """
    mutation Follow($username: String!) {
      follow(username: $username) {
        result {
          username
          bio
        }
        ...errorFields
      }
    }
    #{errors_on("ProfileResult")}
  """

  @unfollow_mutation """
    mutation Unfollow($username: String!) {
      unfollow(username: $username) {
        result {
          username 
        }
        ...errorFields
      }
    }
    #{errors_on("ProfileResult")}
  """

  test "successful registration", %{conn: conn} do
    params =
      build(:user)
      |> Map.from_struct()
      |> Map.take([:username, :password, :email, :image, :bio])

    response =
      conn
      |> graphql_query(query: @register_mutation, variables: %{user: params})
      |> Map.fetch!("data")
      |> Map.fetch!("register")
      |> Map.fetch!("result")

    assert Map.fetch!(response, "email") == params[:email]
  end

  test "failed registration, username already taken", %{conn: conn, user: user} do
    params =
      build(:user, username: user.username)
      |> Map.from_struct()
      |> Map.take([:username, :password, :email, :image, :bio])

    response =
      conn
      |> graphql_query(query: @register_mutation, variables: %{user: params})
      |> Map.fetch!("data")
      |> Map.fetch!("register")

    assert Map.fetch!(response, "successful") == false
  end

  test "successful login", %{conn: conn, user: user} do
    params = %{email: user.email, password: "password"}

    response =
      conn
      |> graphql_query(query: @login_mutation, variables: params)
      |> Map.fetch!("data")
      |> Map.fetch!("login")

    assert Map.fetch!(response, "email") == user.email
    assert Map.fetch!(response, "token") != nil
  end

  test "failed login, wrong password", %{conn: conn, user: user} do
    params = %{email: user.email, password: "wrong"}

    response =
      conn
      |> graphql_query(query: @login_mutation, variables: params)
      |> Map.fetch!("data")
      |> Map.fetch!("login")

    err =
      conn
      |> graphql_query(query: @login_mutation, variables: params)
      |> Map.fetch!("errors")

    assert response == nil
    assert err |> List.first() |> Map.fetch!("message") == "Could not login"
  end

  test "update user", %{conn: conn, user: user} do
    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(
        query: @update_me_mutation,
        variables: %{user: %{username: "some-other-name"}}
      )
      |> Map.fetch!("data")
      |> Map.fetch!("updateMe")
      |> Map.fetch!("result")

    assert Map.fetch!(response, "username") === "some-other-name"
  end

  test "failed user update, username already taken", %{
    conn: conn,
    user: user,
    other_user: other_user
  } do
    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(
        query: @update_me_mutation,
        variables: %{user: %{username: other_user.username}}
      )
      |> Map.fetch!("data")
      |> Map.fetch!("updateMe")

    assert Map.fetch!(response, "result") == nil
  end

  test "follow user", %{conn: conn, user: user, other_user: other_user} do
    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(query: @follow_mutation, variables: %{username: other_user.username})
      |> Map.fetch!("data")
      |> Map.fetch!("follow")
      |> Map.fetch!("result")

    assert Map.fetch!(response, "username") == other_user.username
  end

  test "follow unknown user", %{conn: conn, user: user} do
    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(query: @follow_mutation, variables: %{username: "no-such-person"})
      |> Map.fetch!("data")
      |> Map.fetch!("follow")

    assert Map.fetch!(response, "result") == nil

    assert Map.fetch!(response, "messages") |> List.first() |> Map.fetch!("message") ==
             "user not found"
  end

  test "unfollow user", %{conn: conn, user: user} do
    followee = insert(:user)
    _follow = insert(:follow, user_id: user.id, followee_id: followee.id)

    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(query: @unfollow_mutation, variables: %{username: followee.username})
      |> Map.fetch!("data")
      |> Map.fetch!("unfollow")
      |> Map.fetch!("result")

    assert Map.fetch!(response, "username") == followee.username
  end

  test "unfollow unknown user", %{conn: conn, user: user} do
    response =
      conn
      |> authenticate_user(user)
      |> graphql_query(query: @unfollow_mutation, variables: %{username: "no-such-person"})
      |> Map.fetch!("data")
      |> Map.fetch!("unfollow")

    assert Map.fetch!(response, "result") == nil

    assert Map.fetch!(response, "messages") |> List.first() |> Map.fetch!("message") ==
             "user not found"
  end
end
