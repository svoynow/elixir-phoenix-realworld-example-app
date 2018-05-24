defmodule RealWorldWeb.Schema.Types do
  use Absinthe.Schema.Notation
  import Kronky.Payload
  import RealWorld.Schema.Helpers

  import_types(Kronky.ValidationMessageTypes)

  alias RealWorldWeb.Resolvers
  import Absinthe.Resolution.Helpers

  object :base_user do
    field(:username, non_null(:string))
    field(:bio, :string)
    field(:image, :string)
  end

  object :timestamps do
    field(:created_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end

  object :content_fields do
    field(:body, non_null(:string))
    field(:author, non_null(:profile), resolve: dataloader(RealWorld.Blog))
  end

  object :profile do
    import_fields(:base_user)
    field(:following, non_null(:boolean), resolve: &Resolvers.Accounts.following?/3)
    field(:articles, required_list(:article), resolve: dataloader(RealWorld.Blog))

    field(
      :favorited_articles,
      required_list(:article),
      resolve: &Resolvers.Accounts.favorited_articles/3
    )
  end

  payload_object(:profile_result, :profile)

  object :user do
    import_fields(:base_user)
    field(:email, non_null(:string))
    field(:token, non_null(:string))
  end

  payload_object(:user_result, :user)

  object :input_error do
    field(:key, non_null(:string))
    field(:message, non_null(:string))
  end

  object :article do
    field(:slug, :string)
    field(:title, non_null(:string))
    field(:description, non_null(:string))
    field(:tag_list, required_list(:string))
    field(:favorites_count, non_null(:integer), resolve: &Resolvers.Articles.favorite_count/3)
    import_fields(:timestamps)
    import_fields(:content_fields)
    field(:favorited, non_null(:boolean), resolve: &Resolvers.Articles.is_favorite?/3)
  end

  payload_object(:article_result, :article)

  payload_object(:comment_result, list_of(:comment))

  object :comment do
    field(:id, non_null(:integer))
    import_fields(:timestamps)
    import_fields(:content_fields)
  end

  input_object :article_update do
    field(:title, :string)
    field(:description, :string)
    field(:body, :string)
  end

  input_object :article_create do
    field(:title, non_null(:string))
    field(:description, non_null(:string))
    field(:body, :string)
    field(:tag_list, list_of(non_null(:string)))
  end

  input_object :comment_create do
    field(:body, non_null(:string))
  end

  input_object :user_create do
    field(:username, :string)
    field(:email, :string)
    field(:password, :string)
    field(:bio, :string)
    field(:image, :string)
  end

  object :deletion do
    field(:success, non_null(:boolean))
  end

  payload_object(:deletion_result, :deletion)

  scalar :date do
    parse(fn input ->
      with %Absinthe.Blueprint.Input.String{value: value} <- input,
           {:ok, date} <- Date.from_iso8601(value) do
        {:ok, date}
      else
        _ -> :error
      end
    end)

    serialize(fn date ->
      Date.to_iso8601(date)
    end)
  end

  scalar :datetime do
    parse(fn input ->
      with %Absinthe.Blueprint.Input.String{value: value} <- input,
           {:ok, date} <- DateTime.from_iso8601(value) do
        {:ok, date}
      else
        _ -> :error
      end
    end)

    serialize(fn date ->
      DateTime.to_iso8601(date)
    end)
  end

  scalar :decimal do
    parse(fn
      %{value: value}, _ ->
        Decimal.parse(value)

      _, _ ->
        :error
    end)

    serialize(&to_string/1)
  end

  enum :sort_order do
    value(:asc)
    value(:desc)
  end
end
