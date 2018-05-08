defmodule RealWorld.Factory do
  use ExMachina.Ecto, repo: RealWorld.Repo

  def user_factory do
    %RealWorld.Accounts.User{
      email: sequence(:email, &"email-#{&1}@example.com"),
      username: sequence(:username, &"user#{&1}"),
      password: "some password",
      bio: "some bio",
      image: "some image"
    }
  end

  def article_factory do
    %RealWorld.Blog.Article{
      body: "some body",
      description: "some description",
      title: sequence(:title, &"article-#{&1}"),
      tag_list: ["tag1", "tag2"],
      slug: sequence(:slug, &"article-slug-#{&1}"),
      author: build(:user)
    }
  end

  def follow_factory do
    %RealWorld.Accounts.UserFollower{
      user_id: build(:user).id,
      followee_id: build(:user).id
    }
  end

  def comment_factory do
    %RealWorld.Blog.Comment{
      body: "some body",
      author: build(:user)
    }
  end

  def favorite_factory do
    %RealWorld.Blog.Favorite{
      user: build(:user),
      article: build(:article)
    }
  end
end
