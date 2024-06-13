defmodule ElixirPopularity.HackerNewsItemIdProducer do
  use GenServer, restart: :transient

  require Logger

  alias ElixirPopularity.RMQPublisher

  @default_threshold 50_000
  @default_batch_size 30_000
  @default_poll_rate 30_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start do
    GenServer.call(__MODULE__, :start)
  end

  def pause do
    GenServer.call(__MODULE__, :pause)
  end

  @impl true
  def init(_opts) do
    state = %{
      current_id: 2_306_006,
      end_id: 21_672_858,
      threshold: @default_threshold,
      batch_size: @default_batch_size,
      poll_rate: @default_poll_rate,
      timer_ref: nil
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:start, _from, state) do
    Logger.info("Starting items processing...")

    send(self(), :poll_queue_size)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:pause, _from, state) do
    Logger.info("Pausing items processing...")

    Process.cancel_timer(state.timer_ref)

    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:poll_queue_size, %{current_id: current_id, end_id: end_id} = state)
      when current_id > end_id do
    Logger.info("All items have been processed. Shutting down.")
    {:stop, :normal, state}
  end

  def handle_info(:poll_queue_size, state) do
    queue_size = RMQPublisher.hn_item_ids_queue_size()

    new_current_id =
      if queue_size < state.threshold do
        upper_range = min(state.current_id + state.batch_size, state.end_id)

        Logger.info("Enqueueing items #{state.current_id} - #{upper_range}")

        state.current_id..upper_range
        |> Enum.each(&RMQPublisher.publish_hn_item_id("#{&1}"))

        upper_range + 1
      else
        Logger.info(
          "Queue size of #{queue_size} is greater than threshold of #{state.threshold}. Skipping enqueuing."
        )

        state.current_id
      end

    new_state =
      state
      |> Map.put(:current_id, new_current_id)
      |> Map.put(:timer_ref, schedule_next_poll(state.poll_rate))

    {:noreply, new_state}
  end

  defp schedule_next_poll(poll_rate) do
    Logger.info("Scheduling next queue poll.")
    Process.send_after(self(), :poll_queue_size, poll_rate)
  end
end
