defmodule Finsta.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :caption, :string
    field :image_path, :string
    field :likes_count, :integer, default: 0
    belongs_to :user, Finsta.Accounts.User

    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:caption, :image_path, :user_id, :likes_count])
    |> validate_required([:caption, :image_path, :user_id])
  end
end
