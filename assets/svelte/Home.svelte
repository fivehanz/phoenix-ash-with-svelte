<script>
  import { AppShell, AppBar, LightSwitch } from "@skeletonlabs/skeleton";
</script>

<AppShell>
  <!-- header -->
  <svelte:fragment slot="header">
    <AppBar>
      <svelte:fragment slot="lead">
        <h2 class="h2">app bar</h2>
      </svelte:fragment>
      <svelte:fragment slot="trail">
        <LightSwitch />
      </svelte:fragment>
    </AppBar>
  </svelte:fragment>

  <!-- main section -->
  <main class="px-2 flex items-center min-h-screen main-text-gradient">
    <div class="mx-auto max-w-[43rem]">
      <div class="text-center my-3">
        <h1 class="h1">
          <span
            class="bg-gradient-to-br from-red-500 to-yellow-500 bg-clip-text text-transparent box-decoration-clone"
          >
            hello from a svelte component within phoenix framework
          </span>
        </h1>
      </div>
    </div>
  </main>

  <!-- footer -->
  <svelte:fragment slot="pageFooter">
    <!--Copyright section-->
    <div class="p-4 text-center variant-soft-surface">
      © {new Date().getFullYear()}
    </div>
  </svelte:fragment>
</AppShell>
