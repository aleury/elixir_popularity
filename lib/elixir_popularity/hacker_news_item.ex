defmodule ElixirPopularity.HackerNewsItem do
  @type t :: %__MODULE__{
          text: String.t(),
          type: String.t(),
          title: String.t(),
          time: DateTime.t()
        }

  defstruct [:text, :type, :title, :time]

  @spec create(map()) :: t()
  def create(params) do
    %__MODULE__{
      text: params["text"],
      type: params["type"],
      title: params["title"],
      time: parse_time(params["time"])
    }
  end

  defp parse_time(nil), do: nil

  defp parse_time(time) do
    DateTime.from_unix!(time)
  end
end
