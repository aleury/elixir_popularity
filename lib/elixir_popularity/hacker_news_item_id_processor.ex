defmodule ElixirPopularity.HackerNewsItemIdProcessor do
  use Broadway

  alias Broadway.Message
  alias ElixirPopularity.{HackerNewsApi, RMQPublisher}

  def start_link(_opts) do
    Broadway.start_link(
      __MODULE__,
      name: __MODULE__,
      producer: [
        module: {
          BroadwayRabbitMQ.Producer,
          queue: RMQPublisher.item_ids_queue_name(),
          declare: [durable: true],
          on_failure: :reject_and_requeue
        },
        concurrency: 1
      ],
      processors: [
        default: [concurrency: 100]
      ],
      batchers: [
        default: [
          batch_size: 10,
          batch_timeout: 10_000,
          concurrency: 2
        ]
      ]
    )
  end

  @impl true
  def handle_message(_processer, message, _context) do
    Message.update_data(message, fn item_id ->
      {item_id, HackerNewsApi.get_item(item_id)}
    end)
  end

  @impl true
  def handle_batch(_batcher, messages, _batch_info, _context) do
    messages
    |> Enum.reject(&fetch_failed?/1)
    |> Enum.map(&to_map/1)
    |> Jason.encode!()
    |> RMQPublisher.publish_hn_items()

    messages
  end

  defp to_map(%Message{data: {item_id, item}}) do
    %{id: item_id, item: Map.from_struct(item)}
  end

  defp fetch_failed?(%Message{data: {_item_id, :error}}), do: true
  defp fetch_failed?(_), do: false
end
