defmodule BanchanWeb.StudioLive.Show do
  @moduledoc """
  LiveView for viewing individual Studios
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.LiveRedirect

  alias Banchan.Studios
  alias BanchanWeb.Components.{Card, Layout}
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"slug" => slug}, session, socket) do
    socket = assign_defaults(session, socket, false)
    studio = Studios.get_studio_by_slug!(slug)
    members = Studios.list_studio_members(studio)

    current_user_member? =
      socket.assigns.current_user &&
        Studios.is_user_in_studio(socket.assigns.current_user, studio)

    {:ok,
     assign(socket, studio: studio, members: members, current_user_member?: current_user_member?)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <:hero>
        <section class="hero is-primary">
          <div class="hero-body">
            <p class="title">
              {@studio.name}
            </p>
            <p class="subtitle">
              {@studio.description}
              {#if @current_user_member?}
                <LiveRedirect
                  class="button is-light is-small"
                  label="Edit Profile"
                  to={Routes.studio_edit_path(Endpoint, :edit, @studio.slug)}
                />
              {/if}
            </p>
          </div>
        </section>
      </:hero>
      <div class="studio columns">
        <div class="column is-two-thirds">
          <div class="offerings columns is-multiline">
            <div class="column is-one-third">
              <Card>
                <:header>
                  Illustration
                </:header>
                <:header_aside>
                  <span class="tag is-medium is-danger is-light">5/5 slots</span>
                </:header_aside>
                <:image>
                  <figure class="image is-16by9">
                    <img src={Routes.static_path(Endpoint, "/images/640x360.png")}>
                  </figure>
                </:image>
                <div class="content">
                  <p>A waist-up illustration of your character with background of choice!</p>
                  <p>$500-$1000</p>
                </div>
                <:footer>
                  <a class="button is-primary card-footer-item" href="#">Get It</a>
                </:footer>
              </Card>
            </div>

            <div class="column is-one-third">
              <Card>
                <:header>
                  Character
                </:header>
                <:header_aside>
                  <span class="tag is-medium is-success is-light">2/5 slots</span>
                </:header_aside>
                <:image>
                  <figure class="image is-16by9">
                    <img src={Routes.static_path(Endpoint, "/images/640x360.png")}>
                  </figure>
                </:image>
                <div class="content">
                  <p>A clean full-body illustration of your character with NO background!</p>
                  <p>$225-$500+</p>
                </div>
                <:footer>
                  <a class="button is-primary card-footer-item" href="#">Get It</a>
                </:footer>
              </Card>
            </div>

            <div class="column is-one-third">
              <Card>
                <:header>
                  Character Page
                </:header>
                <:header_aside>
                  <span class="tag is-medium is-warning is-light">2/3 slots</span>
                </:header_aside>
                <:image>
                  <figure class="image is-16by9">
                    <img src={Routes.static_path(Endpoint, "/images/640x360.png")}>
                  </figure>
                </:image>
                <div class="content">
                  <p>A page spread depicting your character in a variety of illustrations collaged together!</p>
                  <p>$225-$600+</p>
                </div>
                <:footer>
                  <a class="button is-primary card-footer-item" href="#">Get It</a>
                </:footer>
              </Card>
            </div>

            <div class="column is-one-third">
              <Card>
                <:header>
                  Chibi Icon
                </:header>
                <:header_aside>
                  <span class="tag is-medium is-success is-light">3/10 slots</span>
                </:header_aside>
                <:image>
                  <figure class="image is-16by9">
                    <img src={Routes.static_path(Endpoint, "/images/640x360.png")}>
                  </figure>
                </:image>
                <p>A rendered bust of your character in a chibi/miniaturized style! Square composition for icon use.</p>
                <p>$100-$200</p>
                <:footer>
                  <a class="button is-primary card-footer-item" href="#">Get It</a>
                </:footer>
              </Card>
            </div>

            <div class="column is-one-third">
              <Card>
                <:header>
                  Character Bust
                </:header>
                <:header_aside>
                  <span class="tag is-medium is-danger is-light">5/5 slots</span>
                </:header_aside>
                <:image>
                  <figure class="image is-16by9">
                    <img src={Routes.static_path(Endpoint, "/images/640x360.png")}>
                  </figure>
                </:image>
                <p>A rendered bust of your character in a chibi/miniaturized style! Square composition for icon use.</p>
                <p>$75-$150</p>
                <:footer>
                  <a class="button is-primary card-footer-item" href="#">Get It</a>
                </:footer>
              </Card>
            </div>
          </div>
        </div>

        <div class="column">
          <div class="block">
            <h2 class="subtitle">Members</h2>
            <div class="studio-members columns is-multiline">
              {#for member <- @members}
                <div class="column">
                  <figure class="column image is-64x64">
                    <LiveRedirect to={Routes.denizen_show_path(Endpoint, :show, member.handle)}>
                      <img
                        alt={member.name}
                        class="is-rounded"
                        src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}
                      />
                    </LiveRedirect>
                  </figure>
                </div>
              {/for}
            </div>
          </div>

          <div class="block">
            <h2 class="subtitle">Portfolio</h2>
            portfolio tiles go here
          </div>
        </div>
      </div>
    </Layout>
    """
  end
end
