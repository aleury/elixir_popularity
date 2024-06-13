defmodule ElixirPopularity.HackerNewsItemProcessor do
  use Broadway

  alias Broadway.Message
  alias ElixirPopularity.{ItemStats, Repo, RMQPublisher}

  def start_link(_opts) do
    Broadway.start_link(
      __MODULE__,
      name: __MODULE__,
      producer: [
        module: {
          BroadwayRabbitMQ.Producer,
          queue: RMQPublisher.bulk_item_data_queue_name(),
          declare: [durable: true],
          on_failure: :reject_and_requeue
        },
        concurrency: 1
      ],
      processors: [
        default: [concurrency: 20]
      ]
    )
  end

  def handle_message(_processor, %Message{data: data} = message, _context) do
    data
    |> Jason.decode!()
    |> Enum.map(&summarize_entry/1)
    |> Enum.filter(&languages_present?/1)
    |> Enum.each(&save_item_stats/1)

    message
  end

  defp save_item_stats(attrs) do
    %{id: item_id, type: item_type, date: date} = attrs

    attrs.languages_present
    |> Enum.each(fn
      {lang, true} ->
        %ItemStats{}
        |> ItemStats.changeset(%{
          item_id: item_id,
          item_type: item_type,
          language: Atom.to_string(lang),
          date: date,
          occurances: 1
        })
        |> Repo.insert()

      {_lang, false} ->
        nil
    end)
  end

  defp summarize_entry(entry) do
    %{
      id: entry["id"],
      date: get_in(entry, ["item", "time"]),
      type: get_in(entry, ["item", "type"]),
      languages_present: language_check(entry["item"])
    }
  end

  defp languages_present?(%{languages_present: languages}) do
    languages
    |> Map.values()
    |> Enum.any?()
  end

  defp language_check(%{"type" => "story", "text" => text}) when not is_nil(text) do
    process_text(text)
  end

  defp language_check(%{"type" => "story", "title" => text}) when not is_nil(text) do
    process_text(text)
  end

  defp language_check(%{"type" => "comment", "text" => text}) when not is_nil(text) do
    process_text(text)
  end

  defp language_check(%{"type" => "job", "text" => text}) when not is_nil(text) do
    process_text(text)
  end

  defp language_check(_item) do
    %{
      elixir: false,
      erlang: false
    }
  end

  defp process_text(text) do
    [elixir: ~r/elixir/i, erlang: ~r/erlang/i]
    |> Enum.map(fn {lang, regex} ->
      {lang, String.match?(text, regex)}
    end)
    |> Map.new()
  end
end
