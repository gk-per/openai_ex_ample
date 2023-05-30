defmodule OpenaiExAmple do
  @moduledoc """
  Documentation for `OpenaiExAmple`.
  """

  def run() do
    "veggie guide.md"
    |> read_file()
  end

  def read_file(file_path) do
    File.stream!(file_path)
    |> Stream.map(&String.trim/1)
    |> Enum.to_list()
    |> Enum.reject(&(&1 == ""))
    |> get_and_store_embeddings()
  end

  # Get OpenAI vector embeddings for a list of strings and store them in Redis
  def get_and_store_embeddings(strings) do
    # Establish a connection to the Redis database
    {:ok, conn} = Redix.start_link("redis://localhost:6379", port: 6379)

    for string <- strings do
      IO.inspect("start")
      # Get the embeddings and extract the first one from the list
      {:ok, result} = get_embedding(string)
      embedding = result |> Map.get(:data) |> List.first() |> Map.get("embedding")

      # Convert the embedding to a string representation so it can be stored in Redis
      string_embedding = embedding |> Enum.join(",")

      # Store the embedding in the Redis database
      {:ok, _response} = Redix.command(conn, ["SET", "embedding:#{string}", string_embedding])
      IO.inspect("end")
    end

    # Close the Redis connection
    Redix.stop(conn)
  end

  def get_embedding(string) do
    OpenAI.embeddings(model: "text-embedding-ada-002", input: string)
  end
end
