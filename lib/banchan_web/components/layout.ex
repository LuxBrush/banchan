defmodule BanchanWeb.Components.Layout.NavLink do
  @moduledoc """
  Link inside the side nav bar, including highlights for currently active page.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.Icon

  prop current_page, :string, from_context: :current_page
  prop to, :string, required: true
  prop icon, :string, required: true
  prop title, :string, required: true

  def render(assigns) do
    ~F"""
    <li>
      <LiveRedirect
        class={
          active:
            @current_page == @to || (@current_page == "/discover/studios" && @to == "/discover/offerings")
        }
        to={@to}
      >
        <Icon name={@icon} size="4">
          <span>{@title}</span>
        </Icon>
      </LiveRedirect>
    </li>
    """
  end
end

defmodule BanchanWeb.Components.Layout do
  @moduledoc """
  Standard dynamic part of the layout used for Surface LiveViews.

  We can't have these just in the layout itself because of the dynamic bits.
  """
  use BanchanWeb, :component

  alias Banchan.Accounts

  alias Surface.Components.{Link, LiveRedirect}

  alias BanchanWeb.Components.{Avatar, Flash, Icon, Nav, UserHandle, ViewSwitcher}

  alias BanchanWeb.Components.Layout.NavLink

  prop current_user, :any, from_context: :current_user
  prop flashes, :any, required: true
  prop padding, :integer, default: 4
  prop context, :atom, values: [:personal, :studio, :admin, :dev], default: :personal
  prop studio, :struct

  slot hero
  slot default

  def render(assigns) do
    ~F"""
    <style>
      :global(details) > :global(summary) {
      list-style: none;
      }
      :global(details) > :global(summary::-webkit-details-marker) {
      display: none;
      }
    </style>
    <div class="w-full h-screen drawer drawer-mobile">
      <input
        type="checkbox"
        id="drawer-toggle"
        aria-label="Banchan Art menu"
        class="hidden drawer-toggle"
      />
      <main class="flex flex-col h-screen grow drawer-content">
        <div class="sticky top-0 z-50">
          <Nav />
        </div>
        {#if slot_assigned?(:hero)}
          <#slot {@hero} />
        {/if}
        <section class={"flex flex-col grow p-#{@padding}"}>
          <div class="my-2 alert alert-info" :if={@current_user && is_nil(@current_user.confirmed_at)}>
            <div class="block">
              ⚠️You need to verify your email address before you can do certain things on the site, such as submit new commissions. Please check your email or <LiveRedirect class="link" to={Routes.confirmation_path(Endpoint, :show)}>click here to resend your confirmation</LiveRedirect>.⚠️
            </div>
          </div>
          <Flash flashes={@flashes} />
          <#slot />
        </section>
        <div class="w-full border-t border-base-content border-opacity-10">
          <footer class="px-4 py-8 mx-auto border-none footer max-w-7xl">
            <div>
              <span class="opacity-100 footer-title text-primary">Co-op</span>
              <LiveRedirect to={Routes.static_about_us_path(Endpoint, :show)} class="link link-hover">About Us</LiveRedirect>
              <LiveRedirect to={Routes.static_membership_path(Endpoint, :show)} class="link link-hover">Membership</LiveRedirect>
              <LiveRedirect to={Routes.static_contact_path(Endpoint, :show)} class="link link-hover">Contact</LiveRedirect>
              <LiveRedirect to={~p"/feedback"}>Feedback and Support</LiveRedirect>
            </div>
            <div>
              <span class="opacity-100 footer-title text-primary">Legal</span>
              <LiveRedirect
                to={Routes.static_terms_and_conditions_path(Endpoint, :show)}
                class="link link-hover"
              >Terms and Conditions</LiveRedirect>
              <LiveRedirect to={Routes.static_privacy_policy_path(Endpoint, :show)} class="link link-hover">Privacy policy</LiveRedirect>
              <LiveRedirect to={Routes.static_cookies_policy_path(Endpoint, :show)} class="link link-hover">Cookies policy</LiveRedirect>
              <LiveRedirect to={Routes.static_disputes_policy_path(Endpoint, :show)} class="link link-hover">Disputes Policy</LiveRedirect>
            </div>
            <div>
              <span class="opacity-100 footer-title text-primary">Social</span>
              <LiveRedirect to={~p"/blog"} class="link link-hover">Blog</LiveRedirect>
              <div class="grid grid-flow-col gap-4">
                <a
                  href="https://mastodon.art/@Banchan"
                  aria-label="Banchan Art on Mastodon (opens in new tab)"
                  target="_blank"
                  rel="noopener noreferrer"
                ><i class="text-xl fab fa-mastodon" /></a>
                <a
                  href="https://twitter.com/BanchanArt"
                  aria-label="Banchan Art on Twitter (opens in new tab)"
                  target="_blank"
                  rel="noopener noreferrer"
                ><i class="text-xl fab fa-twitter" /></a>
                <a
                  href="https://discord.gg/FUkTHjGKJF"
                  aria-label="Banchan Art Discord server (opens in new tab)"
                  target="_blank"
                  rel="noopener noreferrer"
                ><i class="text-xl fab fa-discord" /></a>
                <a
                  href="https://github.com/BanchanArt/banchan"
                  aria-label="Banchan Art on Github (opens in new tab)"
                  target="_blank"
                  rel="noopener noreferrer"
                ><i class="text-xl fab fa-github" /></a>
              </div>
            </div>
          </footer>
        </div>
      </main>

      {!-- # TODO: remove this basic auth check on launch --}
      <div
        :if={@current_user || is_nil(Application.get_env(:banchan, :basic_auth))}
        class="drawer-side"
      >
        <label for="drawer-toggle" class="drawer-overlay" />
        <nav class="relative w-64 border-r bg-base-200 border-base-content border-opacity-10">
          <div class="absolute bottom-0 left-0 flex flex-col w-full px-4 pb-6">
            {#if Accounts.active_user?(@current_user)}
              <div class="divider" />
              <div class="flex flex-row items-center">
                <Link
                  class="flex flex-row items-center gap-2 grow hover:cursor-pointer"
                  to={~p"/people/#{@current_user.handle}"}
                >
                  <Avatar class="w-4 h-4" link={false} user={@current_user} />
                  <UserHandle class="text-sm" link={false} user={@current_user} />
                </Link>
                <Link to={Routes.user_session_path(Endpoint, :delete)} method={:delete}>
                  <div class="tooltip" data-tip="Log out">
                    <Icon name="log-out" size="4" label="log out" class="z-50" />
                  </div>
                </Link>
              </div>
            {/if}
          </div>
          <ul tabindex="0" class="flex flex-col gap-2 p-2 menu menu-compact">
            <li :if={Accounts.active_user?(@current_user) &&
              (Accounts.mod?(@current_user) ||
                 Accounts.artist?(@current_user) ||
                 Application.fetch_env!(:banchan, :env) == :dev)}>
              <ViewSwitcher context={@context} studio={@studio} />
            </li>
            <li
              class="bg-transparent rounded-none pointer-events-none select-none h-fit"
              :if={Accounts.active_user?(@current_user) &&
                (Accounts.mod?(@current_user) ||
                   Accounts.artist?(@current_user) ||
                   Application.fetch_env!(:banchan, :env) == :dev)}
            >
              <div class="w-full gap-0 px-2 py-0 m-0 rounded-none divider" />
            </li>
            {#case @context}
              {#match :personal}
                <NavLink to={~p"/"} icon="home" title="Home" />
                <NavLink to={~p"/discover/offerings"} icon="search" title="Discover" />
                {#if Accounts.active_user?(@current_user)}
                  <NavLink to={~p"/commissions"} icon="scroll-text" title="My Commissions" />
                  {#unless Accounts.artist?(@current_user)}
                    <NavLink to={~p"/beta"} icon="clipboard-signature" title="Become an Artist" />
                  {/unless}
                  <NavLink to={~p"/settings"} icon="settings" title="Settings" />
                {#else}
                  <NavLink to={~p"/login"} icon="log-in" title="Log in" />
                  <NavLink to={~p"/register"} icon="user-plus" title="Register" />
                {/if}
              {#match :studio}
                {#if Accounts.active_user?(@current_user) && Accounts.artist?(@current_user)}
                  <NavLink to={~p"/studios/#{@studio.handle}"} icon="store" title="Shop" />
                  <NavLink to={~p"/studios/#{@studio.handle}/commissions"} icon="scroll-text" title="Commissions" />
                  <NavLink to={~p"/studios/#{@studio.handle}/payouts"} icon="coins" title="Payouts" />
                  <NavLink to={~p"/studios/#{@studio.handle}/settings"} icon="settings" title="Settings" />
                {/if}
              {#match :admin}
                {#if Accounts.active_user?(@current_user) && :admin in @current_user.roles}
                  <NavLink to={~p"/admin/reports"} icon="flag" title="Reports" />
                  <NavLink to={~p"/admin/people"} icon="users" title="Users" />
                  <NavLink to={~p"/admin/requests"} icon="inbox" title="Beta Requests" />
                {/if}
              {#match :dev}
                <li>
                  <a href={~p"/admin/dashboard"} target="_blank" rel="noopener noreferrer">
                    <Icon name="layout-panel-top" size="4">
                      <span>LiveDashboard</span>
                    </Icon>
                  </a>
                </li>
                {#if Application.fetch_env!(:banchan, :env) == :prod}
                  <li>
                    <a href="/admin/oban" target="_blank" rel="noopener noreferrer">
                      <Icon name="list-todo" size="4">
                        <span>Oban Web</span>
                      </Icon>
                    </a>
                  </li>
                {/if}
                {#if Application.fetch_env!(:banchan, :env) == :dev}
                  <li>
                    <a href={~p"/admin/sent_emails"} target="_blank" rel="noopener noreferrer">
                      <Icon name="mail-open" size="4">
                        <span>Sent Emails</span>
                      </Icon>
                    </a>
                  </li>
                  <li>
                    <a href="/catalogue" target="_blank" rel="noopener noreferrer">
                      <Icon name="component" size="4">
                        <span>Catalogue</span>
                      </Icon></a>
                  </li>
                {/if}
            {/case}
          </ul>
        </nav>
      </div>
    </div>
    """
  end
end
