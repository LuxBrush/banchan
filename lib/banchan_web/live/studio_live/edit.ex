defmodule BanchanWeb.StudioLive.Edit do
  @moduledoc """
  Edit Studio profile details (separate from Studio settings).
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form

  alias Banchan.Studios
  alias Banchan.Studios.Studio

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.Components.Form.{
    HiddenInput,
    MarkdownInput,
    Submit,
    TagsInput,
    TextInput,
    UploadInput
  }

  alias BanchanWeb.StudioLive.Components.StudioLayout

  @impl true
  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, true, false)

    {:ok,
     assign(socket,
       tags: socket.assigns.studio.tags,
       changeset: Studio.profile_changeset(socket.assigns.studio, %{}),
       remove_card: false,
       remove_header: false
     )
     |> allow_upload(:card_image,
       # TODO: Be less restrictive here
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1,
       max_file_size: 10_000_000
     )
     |> allow_upload(:header_image,
       # TODO: Be less restrictive here
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1,
       max_file_size: 10_000_000
     )}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_event("submit", val, socket) do
    card_image =
      consume_uploaded_entries(socket, :card_image, fn %{path: path}, entry ->
        {:ok,
         Studios.make_card_image!(
           socket.assigns.current_user,
           path,
           socket.assigns.current_user_member? || :admin in socket.assigns.current_user.roles ||
             :mod in socket.assigns.current_user.roles,
           entry.client_type,
           entry.client_name
         )}
      end)
      |> Enum.at(0)

    header_image =
      consume_uploaded_entries(socket, :header_image, fn %{path: path}, entry ->
        {:ok,
         Studios.make_header_image!(
           socket.assigns.current_user,
           path,
           socket.assigns.current_user_member? || :admin in socket.assigns.current_user.roles ||
             :mod in socket.assigns.current_user.roles,
           entry.client_type,
           entry.client_name
         )}
      end)
      |> Enum.at(0)

    case Studios.update_studio_profile(
           socket.assigns.current_user,
           socket.assigns.studio,
           socket.assigns.current_user_member?,
           Enum.into(val["studio"], %{
             "card_img_id" => (card_image && card_image.id) || val["studio"]["card_image_id"],
             "header_img_id" =>
               (header_image && header_image.id) || val["studio"]["header_image_id"]
           })
         ) do
      {:ok, studio} ->
        socket =
          socket
          |> assign(changeset: Studio.profile_changeset(studio, %{}), studio: studio)
          |> put_flash(:info, "Profile updated")
          |> push_redirect(to: Routes.studio_shop_path(Endpoint, :show, studio.handle))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to edit this studio")
         |> push_redirect(
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}
    end
  end

  def handle_event("change", val, socket) do
    changeset =
      socket.assigns.studio
      |> Studio.profile_changeset(val["studio"])
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_card_upload", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:card_image, ref)}
  end

  @impl true
  def handle_event("cancel_header_upload", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:header_image, ref)}
  end

  def handle_event("remove_card", _, socket) do
    {:noreply, assign(socket, remove_card: true)}
  end

  def handle_event("remove_header", _, socket) do
    {:noreply, assign(socket, remove_header: true)}
  end

  def handle_info(%{event: "follower_count_changed", payload: new_count}, socket) do
    {:noreply, socket |> assign(followers: new_count)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout
      id="studio-layout"
      current_user={@current_user}
      flashes={@flash}
      studio={@studio}
      followers={@followers}
      current_user_member?={@current_user_member?}
      padding={0}
      uri={@uri}
    >
      <div class="w-full md:bg-base-300">
        <div class="max-w-xl w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
          <h2 class="text-xl py-6">Edit Studio Profile</h2>
          <Form class="flex flex-col gap-2" for={@changeset} change="change" submit="submit">
            <TagsInput
              id="studio_tags"
              info="Type to search for existing tags. Press Enter or Tab to add the tag. You can make it whatever you want as long as it's 100 characters or shorter."
              name={:tags}
            />
            <TextInput name={:name} info="Display name for studio" icon="user" opts={required: true} />
            <TextInput name={:handle} icon="at" opts={required: true} />
            <div class="relative">
              {#if Enum.empty?(@uploads.card_image.entries) && (@remove_card || !(@studio && @studio.card_img_id))}
                <HiddenInput name={:card_image_id} value={nil} />
                <div class="aspect-video bg-base-300 w-full" />
              {#elseif !Enum.empty?(@uploads.card_image.entries)}
                <button
                  type="button"
                  phx-value-ref={(@uploads.card_image.entries |> Enum.at(0)).ref}
                  class="btn btn-xs btn-circle absolute right-2 top-2"
                  :on-click="cancel_card_upload"
                >✕</button>
                {Phoenix.LiveView.Helpers.live_img_preview(Enum.at(@uploads.card_image.entries, 0),
                  class: "object-cover aspect-video rounded-xl w-full"
                )}
              {#else}
                <button
                  type="button"
                  class="btn btn-xs btn-circle absolute right-2 top-2"
                  :on-click="remove_card"
                >✕</button>
                <HiddenInput name={:card_image_id} value={@studio.card_img_id} />
                <img
                  class="object-cover aspect-video rounded-xl w-full"
                  src={Routes.public_image_path(Endpoint, :image, :studio_card_img, @studio.card_img_id)}
                />
              {/if}
            </div>
            <UploadInput
              label="Card Image"
              hide_list
              crop
              aspect_ratio={16 / 9}
              upload={@uploads.card_image}
              cancel="cancel_card_upload"
            />
            <div class="relative">
              {#if Enum.empty?(@uploads.header_image.entries) &&
                  (@remove_header || !(@studio && @studio.header_img_id))}
                <HiddenInput name={:header_image_id} value={nil} />
                <div class="aspect-header-image bg-base-300 w-full" />
              {#elseif !Enum.empty?(@uploads.header_image.entries)}
                <button
                  type="button"
                  phx-value-ref={(@uploads.header_image.entries |> Enum.at(0)).ref}
                  class="btn btn-xs btn-circle absolute right-2 top-2"
                  :on-click="cancel_header_upload"
                >✕</button>
                {Phoenix.LiveView.Helpers.live_img_preview(Enum.at(@uploads.header_image.entries, 0),
                  class: "object-cover aspect-header-image rounded-xl w-full"
                )}
              {#else}
                <button
                  type="button"
                  class="btn btn-xs btn-circle absolute right-2 top-2"
                  :on-click="remove_header"
                >✕</button>
                <HiddenInput name={:header_image_id} value={@studio.header_img_id} />
                <img
                  class="object-cover aspect-header-image rounded-xl w-full"
                  src={Routes.public_image_path(Endpoint, :image, :studio_header_img, @studio.header_img_id)}
                />
              {/if}
            </div>
            <UploadInput
              label="Header Image"
              crop
              aspect_ratio={3.5 / 1}
              hide_list
              upload={@uploads.header_image}
              cancel="cancel_header_upload"
            />
            <MarkdownInput
              id="about"
              info="Displayed in the 'About' page. The first few dozen characters will also be displayed as the description in studio cards."
              name={:about}
            />
            <Submit label="Save" />
          </Form>
        </div>
      </div>
    </StudioLayout>
    """
  end
end