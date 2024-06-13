defmodule ElixirPopularity.HackerNewsApi do
  @moduledoc """
  Fetches data from the Hacker News API, extracts the
  relevant information and returns a list of HackerNewsItem structs.
  """
  require Logger

  alias ElixirPopularity.HackerNewsItem

  @spec get_item(integer()) :: HackerNewsItem.t() | :error
  def get_item(item_id) do
    get_item(item_id, 4)
  end

  defp get_item(item_id, retries) do
    response =
      item_id
      |> api_url()
      |> HTTPoison.get([], hackney: [pool: :hn_id_pool])

    with {_, {:ok, body}} <- {"hn_api", handle_response(response)},
         {_, {:ok, params}} <- {"decode_response", Jason.decode(body)},
         {_, {:ok, item}} <- {"parse_hn_item", {:ok, HackerNewsItem.create(params)}} do
      item
    else
      {stage, error} ->
        Logger.warning(
          "Failed attempt #{5 - retries} at stage \"#{stage}\" with Hacker News item with id #{item_id}. Error details: #{inspect(error)}"
        )

        if retries > 0 do
          get_item(item_id, retries - 1)
        else
          Logger.warning("Failed to retrieve Hacker News item with id #{item_id}")
          :error
        end
    end
  end

  defp handle_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    {:ok, body}
  end

  defp handle_response({_, invalid_response}) do
    {:error, invalid_response}
  end

  def api_url(item_id) do
    "https://hacker-news.firebaseio.com/v0/item/#{item_id}.json"
  end
end
