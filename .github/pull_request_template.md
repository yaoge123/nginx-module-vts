<!--
Thank you for contributing.

Fill in the sections below. Delete the checklist items that do not apply to
your change rather than leaving them unticked.
-->

## What this changes

<!-- What the change does, and why. Link the issue it fixes, if there is one. -->

## How it was verified

<!--
Say what you actually ran, not what should pass. For example:

  nginx 1.31.4, default configure: t/021 t/025 t/042 -> PASS, 88 tests
  nginx 1.31.4, --without-http-cache: build -> PASS
  nginx 1.30.4, default configure: full suite -> PASS

If you could not build or test it, say so. That is useful to know and is not
held against you.
-->

## Checklist

<!-- These are the things that have broken in this module before. -->

- [ ] Builds with `--without-http-cache` as well as with the cache enabled.
      Code inside `#if (NGX_HTTP_CACHE)` is not compiled in every build.
- [ ] If it changes `ngx_http_vhost_traffic_status_node_t`, it bumps
      `NGX_HTTP_VHOST_TRAFFIC_STATUS_DUMP_FORMAT_VERSION` in
      `src/ngx_http_vhost_traffic_status_dump.h`. The layout is written to the
      dump file and lives in the shared memory zone, so a change to it also
      means a restart rather than a reload, which belongs in `CHANGELOG.md`.
- [ ] If it uses an nginx field or function added in a particular release, it
      is guarded on `nginx_version`. The module still builds against old nginx.
- [ ] If it adds a conversion to a `..._FMT_...` macro, the argument list at
      every `ngx_sprintf()` that uses the macro was counted against it.
      `ngx_sprintf()` is variadic, so the compiler will not catch a mismatch.
- [ ] New behaviour has a test under `t/`, and the `plan tests` count was
      updated.
- [ ] `README.md` and `CHANGELOG.md` are updated if the change is visible to
      users.

## Assistance Disclosure

<!--
The use of AI/LLM tools is allowed, so long as it is disclosed. Knowing how a
change was produced helps us review it properly; it does not count against the
contribution.

Please say to what extent such tooling was used. Examples:

  "No AI was used."
  "I wrote the code, Claude wrote the tests."
  "I asked ChatGPT for an approach, then implemented it myself."
  "Copilot completed the code as I typed it."
  "The patch is entirely generated; I built it and ran the suite."

We expect you to have checked your contribution for correctness either way.

Replace the line below with your disclosure.
-->

_This PR is missing an assistance disclosure._
