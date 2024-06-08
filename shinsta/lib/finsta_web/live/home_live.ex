defmodule FinstaWeb.HomeLive do
  use FinstaWeb, :live_view

  alias Finsta.Posts
  alias Finsta.Posts.Post

  @impl true
  def render(%{loading: true} = assigns) do
    ~H"""
    <div class="flex justify-center items-center h-screen bg-gradient-to-r from-pink-300 via-purple-300 to-indigo-400">
      <p class="text-white text-xl animate-pulse">Shinsta is loading...</p>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="bg-gradient-to-r from-yellow-200 via-red-200 to-pink-300 min-h-screen">
      <header class="bg-white border-b border-gray-200 shadow-lg">
        <div class="max-w-6xl mx-auto px-4 py-2 flex justify-between items-center">
          <h1 class="text-3xl font-bold text-gray-800">Shinsta</h1>
          <.button type="button" class="bg-gradient-to-r from-green-400 to-blue-500 text-white px-4 py-2 rounded hover:from-blue-500 hover:to-green-400" phx-click={show_modal("new-post-modal")}>Create Post</.button>
        </div>
      </header>

      <main class="max-w-6xl mx-auto p-4">
        <div id="feed" phx-update="stream" class="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
          <div :for={{dom_id, post} <- @streams.posts} id={dom_id} class="bg-white border rounded shadow-lg overflow-hidden hover:shadow-2xl transition-shadow duration-300">
            <img src={post.image_path} class="w-full h-64 object-cover" />
            <div class="p-4">
              <p class="font-semibold text-gray-700"><%= post.user.email %></p>
              <p class="text-gray-600"><%= post.caption %></p>
              <p class="text-gray-600">Likes: <%= post.likes_count %></p>
              <button type="button" class="text-blue-500 hover:text-blue-700" phx-click="like-post" phx-value-id={post.id}>Like</button>
            </div>
          </div>
        </div>
      </main>

      <.modal id="new-post-modal">
        <div class="p-4 bg-white rounded shadow-lg">
          <h2 class="text-xl font-semibold mb-4">Create a new post</h2>
          <.simple_form for={@form} phx-change="validate" phx-submit="save-post" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700">Image</label>
              <.live_file_input upload={@uploads.image} required class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700">Caption</label>
              <.input field={@form[:caption]} type="textarea" class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md" label="Caption" required />
            </div>
            <.button type="submit" class="w-full bg-gradient-to-r from-blue-500 to-purple-500 text-white px-4 py-2 rounded hover:from-purple-500 hover:to-blue-500" phx-disable-with="Saving...">Create Post</.button>
          </.simple_form>
        </div>
      </.modal>
    </div>
    """
  end


  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Finsta.PubSub, "posts")

      form =
        %Post{}
        |> Post.changeset(%{})
        |> to_form(as: "post")

      socket =
        socket
        |> assign(form: form, loading: false)
        |> allow_upload(:image, accept: ~w(.png .jpg), max_entries: 1)
        |> stream(:posts, Posts.list_posts())

      {:ok, socket}
    else
      {:ok, assign(socket, loading: true)}
    end
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save-post", %{"post" => post_params}, socket) do
    %{current_user: user} = socket.assigns

    post_params
    |> Map.put("user_id", user.id)
    |> Map.put("image_path", List.first(consume_files(socket)))
    |> Posts.save()
    |> case do
      {:ok, post} ->
        socket =
          socket
          |> put_flash(:info, "Post created successfully!")
          |> push_navigate(to: ~p"/home")

        Phoenix.PubSub.broadcast(Finsta.PubSub, "posts", {:new, Map.put(post, :user, user)})

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new, post}, socket) do
    socket =
      socket
      |> put_flash(:info, "#{post.user.email} just posted!")
      |> stream_insert(:posts, post, at: 0)

    {:noreply, socket}
  end

  defp consume_files(socket) do
    consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
      dest = Path.join([:code.priv_dir(:finsta), "static", "uploads", Path.basename(path)])
      File.cp!(path, dest)

      {:postpone, ~p"/uploads/#{Path.basename(dest)}"}
    end)
  end

  @impl true
  def handle_event("like-post", %{"id" => post_id}, socket) do
    case Posts.like_post(post_id) do
      {:ok, post} ->
        Phoenix.PubSub.broadcast(Finsta.PubSub, "posts", {:update_likes, post})
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:update_likes, post}, socket) do
    socket =
      socket
      |> stream_insert(:posts, post, at: 0)

    {:noreply, socket}
  end
end
