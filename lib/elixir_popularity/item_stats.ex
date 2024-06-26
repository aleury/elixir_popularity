defmodule ElixirPopularity.ItemStats do
  use Ecto.Schema
  import Ecto.Changeset

  schema "hn_item_stats" do
    field :item_id, :string
    field :item_type, :string
    field :language, :string
    field :date, :date
    field :occurances, :integer
  end

  def changeset(item_stats, params \\ %{}) do
    all_fields = ~w(item_id item_type language date occurances)a

    item_stats
    |> cast(params, all_fields)
    |> validate_required(all_fields)
  end
end
