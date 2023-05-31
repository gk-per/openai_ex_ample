defmodule OpenaiExAmple do
  @moduledoc """
  Documentation for `OpenaiExAmple`.
  """

  def run() do
    "input.md"
    |> read_file()
  end

  def read_file(file_path) do
    File.stream!(file_path)
    |> Stream.map(&String.trim/1)
    |> Stream.map(&preprocess/1)
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
      embedding = get_embedding(string)

      # Convert the embedding to a string representation so it can be stored in Redis
      string_embedding = embedding |> Enum.join(",")

      # Store the embedding in the Redis database
      {:ok, _response} = Redix.command(conn, ["SET", "embedding:#{string}", string_embedding])
      IO.inspect("end")
    end

    # Close the Redis connection
    Redix.stop(conn)
  end

  # Function for handling text input to get the embeddings of the input and find the vector closest to the question's embedding using cosine_similarity
  def get_closest_question(question) do
    # Establish a connection to the Redis database
    {:ok, conn} = Redix.start_link("redis://localhost:6379", port: 6379)

    # Get the embeddings and extract the first one from the list
    question_embedding = get_embedding(question)

    # Get all keys from the Redis database
    {:ok, keys} = Redix.command(conn, ["KEYS", "embedding:*"])

    # Get all embeddings from the Redis database
    {:ok, embeddings} = Redix.command(conn, ["MGET"] ++ keys)

    # Convert the embeddings from strings to lists of floats
    embeddings = Enum.map(embeddings, fn embedding -> embedding |> String.split(",") |> Enum.map(&String.to_float/1) end)

    # Calculate the cosine similarity between the question's embedding and all the embeddings in the database
    similarities = Enum.map(embeddings, fn embedding -> cosine_similarity(question_embedding, embedding) end) |> Enum.reject(&(1 - &1 < 0.05 or &1 > 1.0))

    # Get the value of the embedding with the highest similarity
    value = Enum.max_by(similarities, & &1)

    # Get the index of the value from the list of similarities
    index = Enum.find_index(similarities, &(&1 == value))

    IO.inspect(index, label: "index")

    # Get the key of the embedding with the highest similarity
    key = Enum.at(keys, index)

    # Get the question with the highest similarity
    question = String.replace(key, "embedding:", "")

    # Close the Redis connection
    Redix.stop(conn)

    question
  end



  defp get_embedding(string) do
    {:ok, result} = OpenAI.embeddings(model: "text-embedding-ada-002", input: string)
    result |> Map.get(:data) |> List.first() |> Map.get("embedding")
  end

  defp cosine_similarity(a, b) do
    dot_product = Enum.zip_with(a, b, &Kernel.*/2) |> Enum.sum()
    magnitude_a = :math.sqrt(Enum.map(a, &(&1 * &1)) |> Enum.sum())
    magnitude_b = :math.sqrt(Enum.map(b, &(&1 * &1)) |> Enum.sum())
    dot_product / (magnitude_a * magnitude_b)
  end

  defp preprocess(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^\p{L}\p{Nd}\s]/u, "")
  end

end
