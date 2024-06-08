defmodule Finsta.Repo.Migrations.AddLikesCountToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :likes_count, :integer, default: 0
    end
  end
end
