defmodule Finsta.Posts do
  import Ecto.Query, warn: false

  alias Finsta.Repo
  alias Finsta.Posts.Post

  def list_posts do
    query =
      from p in Post,
      select: p,
      order_by: [desc: :inserted_at],
      preload: [:user]

    Repo.all(query)
  end

  def save(post_params) do
    %Post{}
    |> Post.changeset(post_params)
    |> Repo.insert()
  end

  def like_post(post_id) do
    post = Repo.get!(Post, post_id)
    changeset = Ecto.Changeset.change(post, likes_count: post.likes_count + 1)
    Repo.update(changeset)
  end

end
