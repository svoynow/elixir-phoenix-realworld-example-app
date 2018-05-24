defmodule RealWorldWeb.Schema do
  use Absinthe.Schema
  import Kronky.Payload
  import RealWorld.Schema.Helpers

  # import_types(Kronky.ValidationMessageTypes)

  alias RealWorldWeb.Resolvers
  alias RealWorldWeb.Schema.Middleware.{Authorize, LoadResource}

  import_types(__MODULE__.Types)

  def load_article_config do
    %{
      arg: :slug,
      contextKey: :article,
      dataSource: fn slug ->
        case RealWorld.Blog.get_article_by_slug(slug) do
          %RealWorld.Blog.Article{} = article -> {:ok, article}
          err -> {:error, err}
        end
      end,
      error: "Article not found"
    }
  end

  def load_comment_config do
    %{
      arg: :id,
      contextKey: :comment,
      dataSource: fn id ->
        case RealWorld.Blog.get_comment(id) do
          %RealWorld.Blog.Comment{} = comment -> {:ok, comment}
          err -> {:error, err}
        end
      end,
      error: "Comment not found"
    }
  end

  def dataloader() do
    alias RealWorld.Blog
    alias RealWorld.Accounts
    alias RealWorld.Accounts.Users

    Dataloader.new()
    |> Dataloader.add_source(Blog, Blog.data())
    |> Dataloader.add_source(Accounts, Users.data())
  end

  def context(ctx) do
    Map.put(ctx, :loader, dataloader())
  end

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end

  query do
    @desc "currently logged in user"
    field :me, :profile do
      middleware(Authorize, nil)
      resolve(&Resolvers.Accounts.me/3)
    end

    @desc "user profile"
    field :profile, :profile do
      arg(:username, non_null(:string))
      resolve(&Resolvers.Accounts.profile/3)
    end

    @desc "filtered list of articles by tag, author or favorited status"
    field :articles, non_null(list_of(non_null(:article))) do
      arg(:tag, :string)
      arg(:author, :string)
      arg(:favorited, :string)
      arg(:limit, :integer)
      arg(:offset, :integer)
      resolve(&Resolvers.Articles.articles/3)
    end

    @desc "feed of articles by users followed by the logged in user"
    field :feed, non_null(list_of(non_null(:article))) do
      arg(:limit, :integer)
      arg(:offset, :integer)
      middleware(Authorize, nil)
      resolve(&Resolvers.Articles.feed/3)
    end

    @desc "lookup article by slug"
    field :article, :article do
      arg(:slug, :string)
      resolve(&Resolvers.Articles.article/3)
    end

    @desc "comments for an article"
    field :comments, required_list(:comment) do
      arg(:slug, :string)
      middleware(LoadResource, load_article_config())
      resolve(&Resolvers.Comments.for_article/3)
    end

    @desc "all tags"
    field :tags, required_list(:string) do
      resolve(&Resolvers.Tags.list/3)
    end
  end

  mutation do
    @desc "Returns a token for your Authorization header (Token <token_value>)"
    field :login, :user do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))
      resolve(&Resolvers.Accounts.login/3)

      middleware(fn res, _ ->
        with %{value: %{user: user}} <- res do
          %{res | context: Map.put(res.context, :current_user, user)}
        end
      end)
    end

    @desc "register a new user"
    field :register, :user_result do
      arg(:user, non_null(:user_create))
      resolve(&Resolvers.Accounts.register/3)
      middleware(&build_payload/2)
    end

    @desc "update currently logged-in user"
    field :update_me, :user_result do
      arg(:user, non_null(:user_create))
      middleware(Authorize, nil)
      resolve(&Resolvers.Accounts.update/3)
      middleware(&build_payload/2)
    end

    @desc "follow a user"
    field :follow, :profile_result do
      arg(:username, non_null(:string))
      middleware(Authorize, nil)
      resolve(&Resolvers.Accounts.follow/3)
    end

    @desc "unfollow a user"
    field :unfollow, :profile_result do
      arg(:username, non_null(:string))
      middleware(Authorize, nil)
      resolve(&Resolvers.Accounts.unfollow/3)
    end

    @desc "post a new article"
    field :article, :article_result do
      arg(:article, non_null(:article_create))
      middleware(Authorize, nil)
      resolve(&Resolvers.Articles.create/3)
      middleware(&build_payload/2)
    end

    @desc "update an article"
    field :update_article, :article_result do
      arg(:slug, non_null(:string))
      middleware(LoadResource, load_article_config())
      arg(:update, non_null(:article_update))
      middleware(Authorize, [&Authorize.logged_in?/1, &Authorize.owns_article?/1])
      resolve(&Resolvers.Articles.update/3)
      middleware(&build_payload/2)
    end

    @desc "delete an article"
    field :delete_article, :deletion_result do
      arg(:slug, non_null(:string))
      middleware(LoadResource, load_article_config())
      middleware(Authorize, [&Authorize.logged_in?/1, &Authorize.owns_article?/1])
      resolve(&Resolvers.Articles.delete/3)
      middleware(&build_payload/2)
    end

    @desc "favorite an article"
    field :favorite, :article_result do
      arg(:slug, non_null(:string))
      middleware(LoadResource, load_article_config())
      middleware(Authorize, nil)
      resolve(&Resolvers.Articles.favorite/3)
      middleware(&build_payload/2)
    end

    @desc "unfavorite an article"
    field :unfavorite, :article_result do
      arg(:slug, non_null(:string))
      middleware(LoadResource, load_article_config())
      middleware(Authorize, nil)
      resolve(&Resolvers.Articles.unfavorite/3)
      middleware(&build_payload/2)
    end

    @desc "add a comment on an article"
    field :comment, :comment_result do
      arg(:slug, non_null(:string))
      arg(:comment, non_null(:comment_create))
      middleware(LoadResource, load_article_config())
      middleware(Authorize, nil)
      resolve(&Resolvers.Comments.create/3)
      middleware(&build_payload/2)
    end

    @desc "delete comment"
    field :delete_comment, :deletion_result do
      arg(:slug, non_null(:string))
      arg(:id, non_null(:integer))
      middleware(LoadResource, load_article_config())
      middleware(LoadResource, load_comment_config())

      middleware(Authorize, [
        &Authorize.logged_in?/1,
        &Authorize.owns_comment?/1
      ])

      resolve(&Resolvers.Comments.delete/3)
      middleware(&build_payload/2)
    end
  end
end
