defmodule ElixirPopularity.Repo.Migrations.CreateStatsTable do
  use Ecto.Migration

  def change do
    create table(:hn_item_stats) do
      add :item_id, :string, null: false
      add :item_type, :string, null: false
      add :language, :string, null: false
      add :date, :date, null: false
      add :occurances, :integer, null: false
    end

    create index(:hn_item_stats, [:date])
    create index(:hn_item_stats, [:language])
    create index(:hn_item_stats, [:item_id])
    create index(:hn_item_stats, [:item_type])
  end
end
