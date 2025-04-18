# Changelog

## [4.10.0](https://github.com/folke/noice.nvim/compare/v4.9.0...v4.10.0) (2025-02-06)


### Features

* **fzf:** fix fzf integration ([#1048](https://github.com/folke/noice.nvim/issues/1048)) ([f3291db](https://github.com/folke/noice.nvim/commit/f3291db22863021160c16280407bcaf8fe00df61))


### Bug Fixes

* **cmdline:** use number indexed `vim.g.ui_cmdline_pos` ([eaed6cc](https://github.com/folke/noice.nvim/commit/eaed6cc9c06aa2013b5255349e4f26a6b17ab70f))
* **confirm:** fixed `vim.fn.confirm` on nightly (0.11). Closes [#1036](https://github.com/folke/noice.nvim/issues/1036) ([00b5984](https://github.com/folke/noice.nvim/commit/00b598486601974405b2d5135d9ee7fa1638a5c7))
* **fzf-lua:** update `update_title` and `update_scrollbar` to `update_preview_title` and `update_preview_scrollbar` ([#1034](https://github.com/folke/noice.nvim/issues/1034)) ([5530d78](https://github.com/folke/noice.nvim/commit/5530d78ae8a05ba7982af55a373c35fb18699307)), closes [#1029](https://github.com/folke/noice.nvim/issues/1029)
* **nui:** don't error when border win was closed. Fixes [#832](https://github.com/folke/noice.nvim/issues/832) ([d2b092a](https://github.com/folke/noice.nvim/commit/d2b092aa769d5beef83ed32b1b61f09aa92f412f))
* **telescope:** handle hl_group ID correctly in picker ([#1032](https://github.com/folke/noice.nvim/issues/1032)) ([002b202](https://github.com/folke/noice.nvim/commit/002b20226b659c299f6e386e24bc1b8159b999ae)), closes [#1024](https://github.com/folke/noice.nvim/issues/1024)

## [4.9.0](https://github.com/folke/noice.nvim/compare/v4.8.0...v4.9.0) (2024-12-12)


### Features

* **api:** set vim.g.ui_cmdline_pos to (1,0)-indexed position of the noice cmdline ([a45f997](https://github.com/folke/noice.nvim/commit/a45f9975e1fc92f1cfd4a19cc58356deb5d0736c))


### Bug Fixes

* **cmdline:** don't unset `vim.g.ui_cmdline_pos`. Might be useful for others to keep around. ([29a0adb](https://github.com/folke/noice.nvim/commit/29a0adb0b21b087a7209ee3b131cb16af9f60fd4))
* **cmdline:** make ui_cmdline_pos col 0-based ([324e6a8](https://github.com/folke/noice.nvim/commit/324e6a874fdf78d389ab69be46de0523f3af274e))

## [4.8.0](https://github.com/folke/noice.nvim/compare/v4.7.2...v4.8.0) (2024-12-06)


### Features

* **msg:** added support for msg_show list_cmd and input_prompt kinds ([21fe733](https://github.com/folke/noice.nvim/commit/21fe733f8a731c9ea69f43d89b51d5594f9b00db))


### Bug Fixes

* **cmdline:** dont restore cursor after render. Fixes [#959](https://github.com/folke/noice.nvim/issues/959) ([c49a4b0](https://github.com/folke/noice.nvim/commit/c49a4b008a6e4f9ea2fcdca2120f3bf4b91f015f))
* **health:** better health checks ([0f5f8c9](https://github.com/folke/noice.nvim/commit/0f5f8c93dd11546574640c559f5843488e460df6))
* **lsp:** support mixed encoding for lsp clients ([#1004](https://github.com/folke/noice.nvim/issues/1004)) ([c6f6fb1](https://github.com/folke/noice.nvim/commit/c6f6fb178ebe9b4fd90383de743c3399f8c3a37c))
* **msg:** add new msg_show.lua_print to default routes for messages ([0e9853b](https://github.com/folke/noice.nvim/commit/0e9853b73a2a49fc54f4801fd2f79b4a712e7a51))
* **notify:** always convert msg to string if not nil and not string ([3efadda](https://github.com/folke/noice.nvim/commit/3efaddaa24ac8e8c59cc2c7d14e6ee9907a75c6d))
* **nui:** set max size to editor cols ([d9991ca](https://github.com/folke/noice.nvim/commit/d9991ca9ac097d42ab5ec3205a457d930dce63d5))
* **router:** prevent overriding current tick ([e0fd746](https://github.com/folke/noice.nvim/commit/e0fd746d5bfda56bc3ee63862a0fa3731ec43108))
* **ui:** always queue incoming events when already processing ([6c7545a](https://github.com/folke/noice.nvim/commit/6c7545a7e8ee887c1136f14087f11d345ebaaa0b))


### Performance Improvements

* **hacks:** disable redraw hack. Should not be needed. If it breaks a plugin, then it should be fixed there. ([956e3ac](https://github.com/folke/noice.nvim/commit/956e3acfba2562e0bd11a58c27363c380ee1ac88))

## [4.7.2](https://github.com/folke/noice.nvim/compare/v4.7.1...v4.7.2) (2024-11-18)


### Bug Fixes

* **ui:** special handling of msg_show.return_prompt. See [#998](https://github.com/folke/noice.nvim/issues/998) ([6e0c8dc](https://github.com/folke/noice.nvim/commit/6e0c8dcc61282782ac7fa4b9b4b0c910fd3f83d9))
* **ui:** typo ([71ae386](https://github.com/folke/noice.nvim/commit/71ae3869ecce6a804d57a10ba0cde724d5b1d652))


### Performance Improvements

* **block:** use hl_ids directly as hl_group for extmarks. no need to use synIDattr ([742610e](https://github.com/folke/noice.nvim/commit/742610e9958ad4f1146983db2e7356c8105a441c))
* **hl:** use real hl_group ids on nightly instead of ffi ([d5483a0](https://github.com/folke/noice.nvim/commit/d5483a098e26bb59839efa77d0e64a0a6389c988))

## [4.7.1](https://github.com/folke/noice.nvim/compare/v4.7.0...v4.7.1) (2024-11-15)


### Bug Fixes

* **scrollbar:** hide on WinClosed. Fixes [#949](https://github.com/folke/noice.nvim/issues/949) ([ca2e3fe](https://github.com/folke/noice.nvim/commit/ca2e3fea9fb080dcb79d9129d73dac631294fe79))
* **ui:** fix ext_messages in fast_events. Fixes [#997](https://github.com/folke/noice.nvim/issues/997) ([a802e17](https://github.com/folke/noice.nvim/commit/a802e1778a291e466b499e3bb47b5d98d33cc4a0))
* **view:** never set winblend when transparent. Fixes [#971](https://github.com/folke/noice.nvim/issues/971) ([fd7625e](https://github.com/folke/noice.nvim/commit/fd7625e8c23491ffeaaf3fddf2a65e12f6ca9238))

## [4.7.0](https://github.com/folke/noice.nvim/compare/v4.6.0...v4.7.0) (2024-11-09)


### Features

* added snacks backend and made it the default for notify (when avaiable) ([eb7e855](https://github.com/folke/noice.nvim/commit/eb7e8558880996e8acf58e48a366142e9f3d835d))


### Bug Fixes

* **snacks:** honor `Snacks.config.notifier.enabled = false` ([f381a46](https://github.com/folke/noice.nvim/commit/f381a469ddf489f048319c2dbfd4964a3ba8b45f))
* **snacks:** make buffer modifiable when merging in another message ([46fa519](https://github.com/folke/noice.nvim/commit/46fa519d481bba76a9bc4d9f9e716481a93d2b4d))
* **snacks:** notifier ([a55b898](https://github.com/folke/noice.nvim/commit/a55b89853846dac6236ee2bdaa49155f1b754f89))
* **snacks:** pass correct message ids ([73d38cc](https://github.com/folke/noice.nvim/commit/73d38cc939db6553b87e5f72ff732447046bced1))
* **treesitter:** use markdown_inline instead of markdown ([9039e7d](https://github.com/folke/noice.nvim/commit/9039e7dd35b3ef42dfff2457837af1a4d75d930c))
* **view:** added support for multiple backends. Fixes [#986](https://github.com/folke/noice.nvim/issues/986) ([eac7e84](https://github.com/folke/noice.nvim/commit/eac7e84b16765066dc235a4d6cf8102d7436f6cd))


### Performance Improvements

* **status:** cache status messages ([1a74bde](https://github.com/folke/noice.nvim/commit/1a74bdea1d754c99f782d369b1a6115c0c7770ba))

## [4.6.0](https://github.com/folke/noice.nvim/compare/v4.5.2...v4.6.0) (2024-11-02)


### Features

* **lsp:** make signature auto_open for snippets configurable ([0783e22](https://github.com/folke/noice.nvim/commit/0783e229e437941bfd624af0e551dd17bf064cd1))


### Bug Fixes

* **cmdline:** always flush cmdline in on_render. Fixes [#892](https://github.com/folke/noice.nvim/issues/892) ([973e10a](https://github.com/folke/noice.nvim/commit/973e10a001b50087db5f101d66b367d945607a07))
* **lsp:** signature help for snippets ([3d5ad39](https://github.com/folke/noice.nvim/commit/3d5ad39f474c426ceacd13341f7599fcd3068aa2))
* **lsp:** vim.lsp.handlers is deprecated for hover / signature_help. Fixes [#977](https://github.com/folke/noice.nvim/issues/977) ([3cd84d4](https://github.com/folke/noice.nvim/commit/3cd84d402e0b5a56cf06b6c7f644a3cc9a3956a6))
* **mini:** show at most 10 mini messages at a time ([58ed320](https://github.com/folke/noice.nvim/commit/58ed320eeb86eac20fd1477c4027528a2a983c17))
* redraw flush when needed. Fixes [#938](https://github.com/folke/noice.nvim/issues/938) ([c897bc8](https://github.com/folke/noice.nvim/commit/c897bc834c915fe4fa6a6de67b553994d1d267cc))

## [4.5.2](https://github.com/folke/noice.nvim/compare/v4.5.1...v4.5.2) (2024-10-02)


### Bug Fixes

* **treesitter:** upstream API changes. Fixes [#962](https://github.com/folke/noice.nvim/issues/962) ([5070aae](https://github.com/folke/noice.nvim/commit/5070aaeab3d6bf3a422652e517830162afd404e0))

## [4.5.1](https://github.com/folke/noice.nvim/compare/v4.5.0...v4.5.1) (2024-09-18)


### Bug Fixes

* dont redraw when exiting. Fixes [#936](https://github.com/folke/noice.nvim/issues/936). Fixes [#921](https://github.com/folke/noice.nvim/issues/921) ([8c6a024](https://github.com/folke/noice.nvim/commit/8c6a02438f869e79e4d343683bc198ebf4b10d49))
* **hacks:** dont close timer multiple times during exit ([86a4891](https://github.com/folke/noice.nvim/commit/86a4891583d2374fbd6183c16ed46dc00ce37fba))
* **hacks:** only redraw cursor when cmdline is active. Fixes [#950](https://github.com/folke/noice.nvim/issues/950). Fixes [#937](https://github.com/folke/noice.nvim/issues/937). Fixes [#923](https://github.com/folke/noice.nvim/issues/923) ([3373ab5](https://github.com/folke/noice.nvim/commit/3373ab568c7cbf83f1244eab922ece9aeccde1fb))

## [4.5.0](https://github.com/folke/noice.nvim/compare/v4.4.7...v4.5.0) (2024-07-25)


### Features

* redraw improvements ([1698725](https://github.com/folke/noice.nvim/commit/1698725a663aca56bcd07a0e405bc441a5f6613b))

## [4.4.7](https://github.com/folke/noice.nvim/compare/v4.4.6...v4.4.7) (2024-07-24)


### Bug Fixes

* **hacks:** better on_module ([c2ba96e](https://github.com/folke/noice.nvim/commit/c2ba96e09c7544e0ebba2120765fb2a081983d7f))

## [4.4.6](https://github.com/folke/noice.nvim/compare/v4.4.5...v4.4.6) (2024-07-24)


### Bug Fixes

* **health:** dont check health on startup ([9df2913](https://github.com/folke/noice.nvim/commit/9df2913ee9b6440f65d4debf8d2eeec07c249dea))
* **text:** deal with invalid extmark offsets. Fixes [#875](https://github.com/folke/noice.nvim/issues/875) ([15d63b8](https://github.com/folke/noice.nvim/commit/15d63b8da0a2c6b7ad2d3dbe7b473b78710c90f3))

## [4.4.5](https://github.com/folke/noice.nvim/compare/v4.4.4...v4.4.5) (2024-07-22)


### Bug Fixes

* **hacks:** cmp loading ([4f5d1b8](https://github.com/folke/noice.nvim/commit/4f5d1b89daa5b5db4a85f3badf35d0e7eea86308))

## [4.4.4](https://github.com/folke/noice.nvim/compare/v4.4.3...v4.4.4) (2024-07-21)


### Bug Fixes

* **hacks:** schedule fixing cmp. Fixes [#910](https://github.com/folke/noice.nvim/issues/910) ([b7515c0](https://github.com/folke/noice.nvim/commit/b7515c038ad9047e0332ca379a71d7640f53c919))
* remove a bunch of hacks that are no longer needed ([5e55d0d](https://github.com/folke/noice.nvim/commit/5e55d0d46f672077f6ae0b69f4f6dfeb63b9ea33))


### Performance Improvements

* **scrollbar:** only show when needed ([7723c2b](https://github.com/folke/noice.nvim/commit/7723c2b1e699708dbe3b2717b21088a09f0eec75))

## [4.4.3](https://github.com/folke/noice.nvim/compare/v4.4.2...v4.4.3) (2024-07-16)


### Bug Fixes

* **mini:** no need to show scrollbar ([c661f95](https://github.com/folke/noice.nvim/commit/c661f955055b7341768b044160002b25bddd24af))
* **syntax:** prevent invalid group names. Closes [#903](https://github.com/folke/noice.nvim/issues/903) ([3b5ea55](https://github.com/folke/noice.nvim/commit/3b5ea551448bd769976428458c11ae3f5849b7ba))

## [4.4.2](https://github.com/folke/noice.nvim/compare/v4.4.1...v4.4.2) (2024-07-15)


### Performance Improvements

* **message:** replace vim.b.messages with lua variable ([#898](https://github.com/folke/noice.nvim/issues/898)) ([7ecc05d](https://github.com/folke/noice.nvim/commit/7ecc05d44c3ed8b9bfa5f6196c0da41d58f93218))

## [4.4.1](https://github.com/folke/noice.nvim/compare/v4.4.0...v4.4.1) (2024-07-12)


### Bug Fixes

* **views:** show confirm at the top so it doesn't obscure the buffer ([2a97893](https://github.com/folke/noice.nvim/commit/2a9789310b6b87e197f27c36e5667a9f1bb4bb24))

## [4.4.0](https://github.com/folke/noice.nvim/compare/v4.3.1...v4.4.0) (2024-07-06)


### Features

* **popupmenu:** add option to hide scrollbar in popupmenu views. ([#686](https://github.com/folke/noice.nvim/issues/686)) ([cd0cd97](https://github.com/folke/noice.nvim/commit/cd0cd97c40fd8594bc727edab16c9e4a0e43dce0))


### Bug Fixes

* **popupmenu:** respect noselect. Fixes [#758](https://github.com/folke/noice.nvim/issues/758) ([d27b118](https://github.com/folke/noice.nvim/commit/d27b118dac86d3a01b025f8a26a33683125ee69e))

## [4.3.1](https://github.com/folke/noice.nvim/compare/v4.3.0...v4.3.1) (2024-06-27)


### Bug Fixes

* **pkg:** and don't set event either ([01d57f9](https://github.com/folke/noice.nvim/commit/01d57f9666a4f2a22f9c1f4e549946083f8a827b))
* **pkg:** don't set `opts = {}`. Too many people manually call setup, so that would break their setup. Sigh.. ([bf971a9](https://github.com/folke/noice.nvim/commit/bf971a9072e738d543aaa8e1fc4b653cebc64db9))

## [4.3.0](https://github.com/folke/noice.nvim/compare/v4.2.2...v4.3.0) (2024-06-23)


### Features

* allow to press Enter to open a window to view message content in telescope ([#796](https://github.com/folke/noice.nvim/issues/796)) ([88ac368](https://github.com/folke/noice.nvim/commit/88ac36864b5976a64b14a8f156c616f41b32f228))


### Bug Fixes

* **cmdline_input:** force a border. Set cmdline input view to something else if you don't want inputprompt in a title. Closes [#866](https://github.com/folke/noice.nvim/issues/866) ([d38ca25](https://github.com/folke/noice.nvim/commit/d38ca2535fb750b835bbfff1948f7f729494b804))
* **mini:** update view options of underlying view. See [#685](https://github.com/folke/noice.nvim/issues/685) ([7ee3649](https://github.com/folke/noice.nvim/commit/7ee3649b9b5f4df5b44ae63ed85b2c9fc834a124))
* **scrollbar:** fix scrollbar. Fixes [#759](https://github.com/folke/noice.nvim/issues/759). Fixes [#727](https://github.com/folke/noice.nvim/issues/727) ([e292a01](https://github.com/folke/noice.nvim/commit/e292a011d5cf331f35e4d0ffdd6bd6e644a1fcef))

## [4.2.2](https://github.com/folke/noice.nvim/compare/v4.2.1...v4.2.2) (2024-06-16)


### Bug Fixes

* **hover:** ignore invalid markup. Fixes [#819](https://github.com/folke/noice.nvim/issues/819) ([59e633f](https://github.com/folke/noice.nvim/commit/59e633ff95be85cf65ac5dc5ece2a89c2b6c403d))
* **msg:** clear existing confirm messages. Fixes [#302](https://github.com/folke/noice.nvim/issues/302) ([d3d8329](https://github.com/folke/noice.nvim/commit/d3d83292c15cb8a72e1e421ddf5a0aac7812cb9c))

## [4.2.1](https://github.com/folke/noice.nvim/compare/v4.2.0...v4.2.1) (2024-06-15)


### Bug Fixes

* **cmdline:** only use cmdline_input for short prompts without newline. Fixes [#856](https://github.com/folke/noice.nvim/issues/856) ([d46c4ba](https://github.com/folke/noice.nvim/commit/d46c4ba67670037bc67af843b95314749caeebf8))

## [4.2.0](https://github.com/folke/noice.nvim/compare/v4.1.0...v4.2.0) (2024-06-13)


### Features

* **cmdline:** icon for cmdline input ([d21d1d6](https://github.com/folke/noice.nvim/commit/d21d1d633762fe51efb6521ddd19942d40911c12))
* **cmdline:** use cmdline prompt as title. Noice is now great for vim.ui.input out of the box ([4c1efad](https://github.com/folke/noice.nvim/commit/4c1efadccc5d4568e3abf0afdd3ee0c5c27b4be9))


### Bug Fixes

* **cmdline_input:** put in same position as cmdline_popup ([e55ce94](https://github.com/folke/noice.nvim/commit/e55ce94a1e4b1b5388e11965072e0cde129604bd))
* **cmdline:** allow overriding title hl ([a5aa639](https://github.com/folke/noice.nvim/commit/a5aa639fb802391293585fca81ac10ecacc5e646))
* **cmdline:** do fix_cursor **after** calculating cmdline position ([ba79352](https://github.com/folke/noice.nvim/commit/ba79352af1527283682fe7b7b049e6c7967cd037))
* **cmdline:** reset title when needed ([edd14df](https://github.com/folke/noice.nvim/commit/edd14df3515b106202fd0def749c3f1206c3bd8c))
* **fzf:** message id ([a9fa1a2](https://github.com/folke/noice.nvim/commit/a9fa1a2ace124fcb752e356b3c52e962c3dcb8b8))
* **nui:** redo layout when border changes ([0327de8](https://github.com/folke/noice.nvim/commit/0327de8b300d81f778b77f9178dec6ba41a0a4af))

## [4.1.0](https://github.com/folke/noice.nvim/compare/v4.0.1...v4.1.0) (2024-06-12)


### Features

* added integrations for fzf-lua ([1605be3](https://github.com/folke/noice.nvim/commit/1605be38bdaa94bc6891e7d310585a9cb16b9dcb))


### Bug Fixes

* **cmdline:** make sure search always uses correct view. Fixes [#841](https://github.com/folke/noice.nvim/issues/841) ([6a8a6de](https://github.com/folke/noice.nvim/commit/6a8a6de79223ac15d8ff5477358e343ae6a6ee51))
* **cmdline:** separate cmdline input view ([07e8f9c](https://github.com/folke/noice.nvim/commit/07e8f9c7dfb01405f8b1173f1d3939b41753779d))
* **fzf:** use --with-nth and skip message id in the display ([ac01164](https://github.com/folke/noice.nvim/commit/ac0116435e53c586a23302650dca73862a251108))

## [4.0.1](https://github.com/folke/noice.nvim/compare/v4.0.0...v4.0.1) (2024-06-04)


### Bug Fixes

* **cmdline:** use real cursors on Neovim &gt;= 0.10 ([5b5fa91](https://github.com/folke/noice.nvim/commit/5b5fa91be6848583cbf824c69e67e26acf609ada))
* disable noice on VimLeavePre so that the user can see exit errors ([31ec80c](https://github.com/folke/noice.nvim/commit/31ec80c99ee699ea4e90248c2e87e5a669be5e93))
* fixup ([cfd7aa4](https://github.com/folke/noice.nvim/commit/cfd7aa4617024a9bd4f6409463c73f91a7f411b8))
* fixup ([2bf0429](https://github.com/folke/noice.nvim/commit/2bf04290b32dc5b1a002a4888c95147bb91ec6f2))
* reduce flickering when searching. See [#679](https://github.com/folke/noice.nvim/issues/679) ([4e1f9f1](https://github.com/folke/noice.nvim/commit/4e1f9f198226aea5b82a6df75e9913b49796cdda))
* remove smart_move ([b6ae820](https://github.com/folke/noice.nvim/commit/b6ae820190dd166d6ebae408d65f2551e37c7bf2))
* search IS blocking, but shouldnt trigger redraw. Fixes [#345](https://github.com/folke/noice.nvim/issues/345) ([b3f08e6](https://github.com/folke/noice.nvim/commit/b3f08e6cf0fd30847f299cc94707563920fd2139))

## [4.0.0](https://github.com/folke/noice.nvim/compare/v3.0.2...v4.0.0) (2024-05-29)


### ⚠ BREAKING CHANGES

* remove cmdpreview hack for nigytly since it's no longer needed there. Update your Nightlies!!

### Bug Fixes

* **markdown:** ignore empty completion documentation tables ([#820](https://github.com/folke/noice.nvim/issues/820)) ([f119045](https://github.com/folke/noice.nvim/commit/f119045f38792ad5311e5f9be7a879e4c1a95fe0))
* remove cmdpreview hack for nigytly since it's no longer needed there. Update your Nightlies!! ([49caf99](https://github.com/folke/noice.nvim/commit/49caf99d6253a43bf55ea055f7fba6c4eb78be20))

## [3.0.2](https://github.com/folke/noice.nvim/compare/v3.0.1...v3.0.2) (2024-05-22)


### Bug Fixes

* **markdown:** keys when buf is invalid ([0dc97cb](https://github.com/folke/noice.nvim/commit/0dc97cb21edac79a1d575541c57a31a3e3bd5b88))

## [3.0.1](https://github.com/folke/noice.nvim/compare/v3.0.0...v3.0.1) (2024-05-18)


### Bug Fixes

* typo with hist messages. Fixes [#815](https://github.com/folke/noice.nvim/issues/815) ([a0a40d3](https://github.com/folke/noice.nvim/commit/a0a40d3e5fdb2eab005e2ee08c4af09c99fcb9a4))

## [3.0.0](https://github.com/folke/noice.nvim/compare/v2.1.1...v3.0.0) (2024-05-18)


### ⚠ BREAKING CHANGES

* bump required Neovim version to >= 0.9

### Features

* bump required Neovim version to &gt;= 0.9 ([6c5290a](https://github.com/folke/noice.nvim/commit/6c5290ad947a97c34889debe59bafe771a9f9578))
* **util:** better debug log ([217c684](https://github.com/folke/noice.nvim/commit/217c6848a6656c5e187d66a2b3caed9a9676d448))


### Bug Fixes

* **cmdline:** use other work-around for cmdpreview ([6a3721b](https://github.com/folke/noice.nvim/commit/6a3721b03dbeb10c3b1c47f63fdc2d77bb550550))
* **msg:** add historical messages as a msg_show instead of history so it doesnt popup ([b9b4818](https://github.com/folke/noice.nvim/commit/b9b481864d0d91c7df539ecebb30a2235a3678da))
* **ui:** dont try updating the ui during textlock ([4ef75a3](https://github.com/folke/noice.nvim/commit/4ef75a3c3893f9efcaf078e60280a9247b9876ff))

## [2.1.1](https://github.com/folke/noice.nvim/compare/v2.1.0...v2.1.1) (2024-05-16)


### Bug Fixes

* fixed check on get_clients. Fixes [#806](https://github.com/folke/noice.nvim/issues/806) ([588471b](https://github.com/folke/noice.nvim/commit/588471bdf26d8fde3fa1672339339a18e1b8568a))

## [2.1.0](https://github.com/folke/noice.nvim/compare/v2.0.3...v2.1.0) (2024-05-16)


### Features

* **config:** added `Noice all` to show ALL messages captured by Noice. See [#769](https://github.com/folke/noice.nvim/issues/769) ([72f72d3](https://github.com/folke/noice.nvim/commit/72f72d3271109ea37128681766de068b62947647))


### Bug Fixes

* **cmdline:** yet another work-around that no longer temporarily changes the cmdline ([68b9c53](https://github.com/folke/noice.nvim/commit/68b9c5395a5e0f4462b4f38791018a48e6929cd9))
* depraction warnings on Neovim 0.11 ([9946087](https://github.com/folke/noice.nvim/commit/9946087bb51a5bfb99efcd1527ef7fe46574cf2f))
* **format:** config.format doesn't work ([#772](https://github.com/folke/noice.nvim/issues/772)) ([09708be](https://github.com/folke/noice.nvim/commit/09708be5668762062d619fddf6cb2b68d165a9c2))
* **messages:** include any messages before Noice was started as one history_show message. Fixes [#799](https://github.com/folke/noice.nvim/issues/799) ([61947de](https://github.com/folke/noice.nvim/commit/61947de3d5904375ea94e0c13db2537488ad9829))
* **messages:** only add previous messages once when Noice starts. Fixes [#804](https://github.com/folke/noice.nvim/issues/804) ([269de18](https://github.com/folke/noice.nvim/commit/269de18e0c4682c8964f278b4fbb9f6ef9a52cd3))
* **msg:** update router when blocking ([ee433a7](https://github.com/folke/noice.nvim/commit/ee433a724c31858537a7d8c80d09c7686810da4a))
* **router:** add additional updates on `SafeState` when available ([fff989f](https://github.com/folke/noice.nvim/commit/fff989f7e5fd3c1e307ac8b92de26be837b18c81))
* **router:** don't use `SafeState` since apparently this is a nightly thing and seems to work without. Fixes [#805](https://github.com/folke/noice.nvim/issues/805) ([ef085e9](https://github.com/folke/noice.nvim/commit/ef085e9cf9ab15a679a403dcfbafba08b9c6cbec))
* **router:** remove SafeState again, since it breaks incsearch ([3c3a8f3](https://github.com/folke/noice.nvim/commit/3c3a8f30061bfbb73308e221d760a3c7c6526473))


### Performance Improvements

* **cmdline:** prevent unneeded redraws during cmdline preview (substitute). Fixes [#803](https://github.com/folke/noice.nvim/issues/803) ([8d924eb](https://github.com/folke/noice.nvim/commit/8d924ebc8e5c28ee30793c30b57d9670884bf05b))
* **ui_attach:** router now only queues messages in `vim.ui_attach`. Use `SafeState` to execute queue when needed. ([4c26991](https://github.com/folke/noice.nvim/commit/4c2699111730a14144224d7b193bede6b707b1bc))

## [2.0.3](https://github.com/folke/noice.nvim/compare/v2.0.2...v2.0.3) (2024-05-15)


### Bug Fixes

* **hacks:** use feedkeys instead of input to force redraw ([dbf8d70](https://github.com/folke/noice.nvim/commit/dbf8d708a46c9d5a6c79f8fc77ac4ffa04d3f0d9))
* **nui:** safely destroy any create window/buffers during E565 errors. Fixes command preview ([a0c6203](https://github.com/folke/noice.nvim/commit/a0c6203d551242322ac7995b26d4e320140e05b1))

## [2.0.2](https://github.com/folke/noice.nvim/compare/v2.0.1...v2.0.2) (2024-05-09)


### Bug Fixes

* **cmdpreview:** read the variable `cmdpreview` in nvim-0.9+ on windows ([#774](https://github.com/folke/noice.nvim/issues/774)) ([a35003d](https://github.com/folke/noice.nvim/commit/a35003dbdd9c8d6d05aa47064de2b76ace872ec4))
* disable incsearch hack for nightly (no longer needed) ([02d698a](https://github.com/folke/noice.nvim/commit/02d698ac0d294e2195429662d0d1cae6cd9a5621))
* **progress:** Change LspProgress data field `result` to `params` ([#785](https://github.com/folke/noice.nvim/issues/785)) ([89de3b5](https://github.com/folke/noice.nvim/commit/89de3b56abee53783dca3500115891fb827669d6))
* retry rendering only once to prevent rendering loops ([f4decbc](https://github.com/folke/noice.nvim/commit/f4decbc7a80229ccc9f86026b74bdcf0c39e38a7))
* **router:** make sure we retry views that could not render due to E565. Fixes [#783](https://github.com/folke/noice.nvim/issues/783) ([6df3d8a](https://github.com/folke/noice.nvim/commit/6df3d8acea83b531deca29e18c64783a3eac106d))
* use `vim.api.nvim__redraw` to update cursor on nightly instead of ffi. Fixes [#781](https://github.com/folke/noice.nvim/issues/781) ([37c8124](https://github.com/folke/noice.nvim/commit/37c8124ee8aac0614a7221c335a97db9ed5e40f3))

## [2.0.1](https://github.com/folke/noice.nvim/compare/v2.0.0...v2.0.1) (2024-03-26)


### Bug Fixes

* **input:** don't filter ^M and &lt;cr&gt; for the command line ([#734](https://github.com/folke/noice.nvim/issues/734)) ([d29b26c](https://github.com/folke/noice.nvim/commit/d29b26c329558ee4bb2e7f3cc25078929ef89b2f))
* lsp message view not effective ([#747](https://github.com/folke/noice.nvim/issues/747)) ([2640d39](https://github.com/folke/noice.nvim/commit/2640d3975d47156c412db6e974a1b1280ff46aab))
* **popup:** don't make the window column go below negative 1 ([#737](https://github.com/folke/noice.nvim/issues/737)) ([01b2b53](https://github.com/folke/noice.nvim/commit/01b2b5316eb6986cc763e7b4f0f0e0f60d2a344b))


### Performance Improvements

* ignore events when setting buf options during render. Fixes [#694](https://github.com/folke/noice.nvim/issues/694) ([bf67d70](https://github.com/folke/noice.nvim/commit/bf67d70bd7265d075191e7812d8eb42b9791f737))
* **lsp:** update lsp progress messages at most every 100ms ([9a9756d](https://github.com/folke/noice.nvim/commit/9a9756d6999abc016c087b9d3fcea3c9de99be98))

## [2.0.0](https://github.com/folke/noice.nvim/compare/v1.16.3...v2.0.0) (2023-10-25)


### ⚠ BREAKING CHANGES

* command redirection! Redirect messages generated by a command or function to a different view
* lsp hover/signatureHelp and message are now enabled by default. Disable in the config if you don't want this.

### Features

* :Noice now has subcommands, full commands and a lua api require("noice").cmd("last") ([88767a6](https://github.com/folke/noice.nvim/commit/88767a64c6b6665b8eca09271d6e0a7b9f53ccaa))
* add `circleFull` spinner ([#495](https://github.com/folke/noice.nvim/issues/495)) ([5427398](https://github.com/folke/noice.nvim/commit/54273980749ceb4396501300bf4c86f3bb818f75))
* add scrollbar to all nui views ([0630e94](https://github.com/folke/noice.nvim/commit/0630e94375c53ecdb64b4d53e1013a0897625d25))
* added `Filter.cond` to conditionally use a route ([29a2e05](https://github.com/folke/noice.nvim/commit/29a2e052d2653443716a8eece89300e9b36b5f2a))
* added `Noice dismiss` to hide all visible messages. Fixes [#417](https://github.com/folke/noice.nvim/issues/417) ([a32bc89](https://github.com/folke/noice.nvim/commit/a32bc892aadb26668fd0161962ae4eccb1bf5854))
* added cmdline formatter help ([7f0ecd8](https://github.com/folke/noice.nvim/commit/7f0ecd88ee3e3ac3d11a8646f1e9a209b4579715))
* added config options for input() cmdline. Fixes [#115](https://github.com/folke/noice.nvim/issues/115) ([b645e30](https://github.com/folke/noice.nvim/commit/b645e30dc228e75b64b28374aa72b6c8ebbbe977))
* added config.lsp.hover. Undocumented for now and disabled by default. ([c2f37ed](https://github.com/folke/noice.nvim/commit/c2f37ed040238573e7a2542e14a814b2c19164bd))
* added configurable commands ([e9ccf78](https://github.com/folke/noice.nvim/commit/e9ccf782c0b4e9f7df47cc30972185e048e0ea67))
* added custom handlers for markdown links and help tags ([37e7203](https://github.com/folke/noice.nvim/commit/37e72034cf336bb4748e15585ab805b3ec2752f4))
* added deactivate ([bf216e0](https://github.com/folke/noice.nvim/commit/bf216e017979f8be712b1ada62736a58e75b0fe3))
* added different closing and focusing ways to lsp hover ([0402182](https://github.com/folke/noice.nvim/commit/04021821b74a8588e20764beb222b71a5fce037c))
* added health check for GUI's with multigrid enabled ([0fdedab](https://github.com/folke/noice.nvim/commit/0fdedab33ac84b133b9c93c0e4d12a51f18d6981))
* added health checks to see if other plugins have overwritten Noice handlers ([906c6c8](https://github.com/folke/noice.nvim/commit/906c6c827dd36176baf9521a0653ca9f29410683))
* added markdown to treesitter health checks ([7c955cc](https://github.com/folke/noice.nvim/commit/7c955cced94bd4eb78d689eddd6528012dcc4bdb))
* added methods that can be mapped for scrolling the hover/signatureHelp windows ([a6ad24e](https://github.com/folke/noice.nvim/commit/a6ad24ed8b9d0b6b0dcde311865547a48cea21da))
* added notify.timeout. Set it on a view to change the deafault timeout ([feaf5c4](https://github.com/folke/noice.nvim/commit/feaf5c43c22a14f5405e7dabd0112974589a6998))
* added option to disable smart_move ([8600a03](https://github.com/folke/noice.nvim/commit/8600a03bf88a2bd817d71829344a8100deaed8b1))
* added option to disable the health checker ([a2f6e4c](https://github.com/folke/noice.nvim/commit/a2f6e4cd831c1c72e92d0f6dc778f68635e82855))
* added optional col to start highlighting with treesitter/syntax ([ccb7e56](https://github.com/folke/noice.nvim/commit/ccb7e561248aab93f67b2b6ab31d75e621b4211c))
* added overrides for default lsp and cmp formatters :) Enable with config.lsp.override ([6d9fb12](https://github.com/folke/noice.nvim/commit/6d9fb1242cd782edfb77ac06b12d72ed24e3888f))
* added preset to set hover docs and signature help border ([e34db67](https://github.com/folke/noice.nvim/commit/e34db671490ebfdc4268fb83602e1a7e06b91e69))
* added routing of LSP window/showMessage ([75730f4](https://github.com/folke/noice.nvim/commit/75730f4b660af682d376c218a16822c782451241))
* added suport for Luasnip jump targets to signature help ([c09d197](https://github.com/folke/noice.nvim/commit/c09d1973e7542ca0201464e053c857e15a2b9f22))
* added support for &lt;pre&gt;{lang} code blocks used in the Neovim codebase ([de48a45](https://github.com/folke/noice.nvim/commit/de48a4528aad5c7b50cf4b4ec1b419762a95934d))
* added support for filtering messages generated by a command on the commandline ([b3ee385](https://github.com/folke/noice.nvim/commit/b3ee38584609d6bf63aceca04fe5463d5ed080ed))
* added support for negative positions. Fixes [#179](https://github.com/folke/noice.nvim/issues/179) ([8d7a63c](https://github.com/folke/noice.nvim/commit/8d7a63c8f003d92c1484045ebe667a62d7625594))
* added title option to cmdline format ([42d771a](https://github.com/folke/noice.nvim/commit/42d771a32ddeb20866907d88d2e95a4730c34807))
* always use the global notify instance and set animate=false when blocking ([edc8df6](https://github.com/folke/noice.nvim/commit/edc8df60a16bb0f2709110b29fef98c6cc616d42))
* automatically move out of the way of existing floating windows. Fixes [#117](https://github.com/folke/noice.nvim/issues/117) ([a810700](https://github.com/folke/noice.nvim/commit/a810700bb8189fe7fb699f388fda6fdb9869fac8))
* better defaults for history and last ([cdb25b8](https://github.com/folke/noice.nvim/commit/cdb25b8a398dae6d72fea3e5721a7c367b2a19f1))
* **cmdline:** added cmdline support for `:lua=` and `:=` ([acfa513](https://github.com/folke/noice.nvim/commit/acfa5133da31a35ec24fca0757ad1c85edc4c585))
* **cmdline:** added support for FloatTitle and added proper default ([79c7059](https://github.com/folke/noice.nvim/commit/79c70594aefb4efecbce4528174fdd0227baaf3e))
* **cmp:** incude item.detail when it's not part of item.documentation ([c2a745a](https://github.com/folke/noice.nvim/commit/c2a745a26ae562f1faecbf6177ac53377d2658d5))
* command redirection! Redirect messages generated by a command or function to a different view ([a8b3117](https://github.com/folke/noice.nvim/commit/a8b3117f22e49dcb44853ca9df84feaa663077bb))
* conceal markdown escape characters. Fixes [#170](https://github.com/folke/noice.nvim/issues/170) ([6824794](https://github.com/folke/noice.nvim/commit/6824794d01fb27e428f642440517fe066bf47105))
* **config:** add calculator to cmdline formats ([#240](https://github.com/folke/noice.nvim/issues/240)) ([fa21685](https://github.com/folke/noice.nvim/commit/fa21685e23cbb72bb573eecf48dd3644bc1513ba))
* don't hide mini messages when blocking [#112](https://github.com/folke/noice.nvim/issues/112) ([6b9144d](https://github.com/folke/noice.nvim/commit/6b9144d3f9873e1651d783c6b862177d5647bd20))
* don't process events that are disabled in config & disable ext that are enabled in the attached GUI ([abb5721](https://github.com/folke/noice.nvim/commit/abb5721129b3f54bb6f38713f45029c61c0e5f64))
* dont show lsp doc when empty ([a61a07f](https://github.com/folke/noice.nvim/commit/a61a07f51398defd6a922e457eabf272ff15ccf3))
* **format:** allow `config.format.level.icons` to be false. Fixes [#274](https://github.com/folke/noice.nvim/issues/274) ([aa68eb6](https://github.com/folke/noice.nvim/commit/aa68eb6f83c48df41bab8ae36623e5af3f224c66))
* **health:** added check for vim-sleuth ([2d11c5b](https://github.com/folke/noice.nvim/commit/2d11c5bfe77c7b93ab5ad7e156e239b8279cc5ee))
* **health:** added markdown_inline to treesitter checks ([d525285](https://github.com/folke/noice.nvim/commit/d5252857db3b295d1b34150531f58f3cc6251192))
* **health:** show what other plugin is overriding a Noice handler ([84dcdf3](https://github.com/folke/noice.nvim/commit/84dcdf3bf453ae1bc4d05a2110e3202e1eb4eafa))
* improved smart move. Added filetype exclusions and only move out when overlap &gt; 30%. Fixes [#130](https://github.com/folke/noice.nvim/issues/130) ([c63267d](https://github.com/folke/noice.nvim/commit/c63267d3649d3b9c5992a4db96a954c8f581cd73))
* keep track of where messages are displayed ([13097dc](https://github.com/folke/noice.nvim/commit/13097dccc8228f07b2aa9191081cc8fa3944af98))
* lsp hover/signatureHelp and message are now enabled by default. Disable in the config if you don't want this. ([9130fd1](https://github.com/folke/noice.nvim/commit/9130fd17a19f95b55ca9362919fef31ab54ef841))
* lsp signature help ([2a19f32](https://github.com/folke/noice.nvim/commit/2a19f32b3d22b0b31812fab76e576e04f06cd2e9))
* **lsp:** added config.lsp.hover.silent. Fixes [#412](https://github.com/folke/noice.nvim/issues/412) ([e2a53cf](https://github.com/folke/noice.nvim/commit/e2a53cf946d88d87cd0123711afce5ddad047b7b))
* **lsp:** added custom formatters for lsp hover and made :help work in hover text ([63c70a9](https://github.com/folke/noice.nvim/commit/63c70a90b033dbd17016bf7e254f7427596dbc3b))
* **lsp:** fallback to buffer filetype for code blocks without lang. Fixes [#378](https://github.com/folke/noice.nvim/issues/378) ([cab2c80](https://github.com/folke/noice.nvim/commit/cab2c80497388735c9795f496a36e76bc5c7c4bf))
* manage message state without `msg_clear` ([#209](https://github.com/folke/noice.nvim/issues/209)) ([fb0e3b0](https://github.com/folke/noice.nvim/commit/fb0e3b0bb3028050b61a45e53809af03b15a24bc))
* markdown formatter ([6ea06c9](https://github.com/folke/noice.nvim/commit/6ea06c926fc3bc495e07ab5a1b51bcb19628d771))
* new markdown renderer without empty lines around code blocks. Fixes [#158](https://github.com/folke/noice.nvim/issues/158) ([111fe5e](https://github.com/folke/noice.nvim/commit/111fe5eaa9d1c5f77ccd427c0139676917c9c162))
* noice presets ([c43d82b](https://github.com/folke/noice.nvim/commit/c43d82b3344e73e85c1af8c994a3dd7a3b4849b5))
* **notify:** added plain renderer ([345fccc](https://github.com/folke/noice.nvim/commit/345fccc9e17bc4fd74361fb0a953d0e87195a657))
* open :messages and history in a split with enter=true ([7beef93](https://github.com/folke/noice.nvim/commit/7beef93fabceefb028a42998150ccd3b5c9b4ea5))
* **popupmenu:** allow different views for regular/cmdline popupmenu ([af706c4](https://github.com/folke/noice.nvim/commit/af706c4b443cf1c416ef7288ec3434f3f1ab6cf1))
* preset for inc_rename ([91c79a0](https://github.com/folke/noice.nvim/commit/91c79a0c51ebb070163668c1156d5cc20c02af3a))
* properly calculate buf height taking wrap into account ([add20ee](https://github.com/folke/noice.nvim/commit/add20ee9ffabc80b34e1b80a53ef68df9969d02e))
* properly calculate layout in case of max_width and wrap ([83c837e](https://github.com/folke/noice.nvim/commit/83c837e1cf39820f275d347e5d65c11e8398e102))
* removed default `&lt;esc&gt;` handler from `split` view ([fb10fa2](https://github.com/folke/noice.nvim/commit/fb10fa2ef7d78953ffb8b9c5fd0f42c389cbedaf))
* replace html entities. Fixes [#168](https://github.com/folke/noice.nvim/issues/168) ([7e3e958](https://github.com/folke/noice.nvim/commit/7e3e9584601a216069f92ab3a33dd2a1af30283f))
* set default view for hover to hover ([dafcddd](https://github.com/folke/noice.nvim/commit/dafcddd583e34444ba4f893d3bece1c12f3a739a))
* set default zindex for hover to 45. Lower than cmp and notify ([0bf5f9e](https://github.com/folke/noice.nvim/commit/0bf5f9e447c5ede0fe7b5c42583e206ed7073b48))
* show warning when running with TUI rework ([cf2231b](https://github.com/folke/noice.nvim/commit/cf2231bfb691b3b58d2685f48da11596cec1cfa3))
* **signature:** added signature param docs. Fixes [#421](https://github.com/folke/noice.nvim/issues/421) ([e76ae13](https://github.com/folke/noice.nvim/commit/e76ae13dd272dc23d0154b93172d445aeabad8f1))
* smart positioning of the hover window. Make sure to update Nui as well to use this. ([5bd6e30](https://github.com/folke/noice.nvim/commit/5bd6e308a10324e0c3d8a320aae234d9ce0a9610))
* Support hide scrollbar for view ([#603](https://github.com/folke/noice.nvim/issues/603)) ([f700175](https://github.com/folke/noice.nvim/commit/f700175b91948e4f71cf73872cea364247cf2dbd))
* **ui:** added hybrid messages functionality, but not needed for now ([addc0a2](https://github.com/folke/noice.nvim/commit/addc0a2521ce666a1f546f9a04574a63a858c6a5))


### Bug Fixes

* accept preset as a table ([#582](https://github.com/folke/noice.nvim/issues/582)) ([53d613c](https://github.com/folke/noice.nvim/commit/53d613cd0031e83987964947b1bad8b5047c9d0e))
* activate vim-sleuth hack. See [#139](https://github.com/folke/noice.nvim/issues/139) ([e99990f](https://github.com/folke/noice.nvim/commit/e99990ffdbf6b65275dd6f51089352d45e7197bc))
* added debugging info for [#220](https://github.com/folke/noice.nvim/issues/220) ([6de461b](https://github.com/folke/noice.nvim/commit/6de461b8475c4f56bc5b8ed93c819c8b15f3e067))
* Allow mapping &lt;esc&gt; ([#329](https://github.com/folke/noice.nvim/issues/329)) ([b7e9054](https://github.com/folke/noice.nvim/commit/b7e9054b02b5958db8bb5ad7675e92bfb5a8e903))
* always show cursorline and reset to line for popupmenu. Fixes [#239](https://github.com/folke/noice.nvim/issues/239) ([c7f666c](https://github.com/folke/noice.nvim/commit/c7f666cff4160a9f9f31e5de112429d6db7956d2))
* anchor popupmenu to SW for bottom cmdline. Fixes [#134](https://github.com/folke/noice.nvim/issues/134) ([9102aef](https://github.com/folke/noice.nvim/commit/9102aef70431cd9959add7bc50d507c18f0089de))
* better handling of splitkeep for nui splits ([84d1904](https://github.com/folke/noice.nvim/commit/84d1904c64759a82149e003bd83442572d588769))
* better way of showing/hiding cursor ([10a97a0](https://github.com/folke/noice.nvim/commit/10a97a0fadfc8929c8aecd9b69dda67b7b2f7a33))
* **block:** better deal with carriage return characters (take 2) ([ee24b36](https://github.com/folke/noice.nvim/commit/ee24b36743b18e53bdc6b49bbfa426fc18ea337a))
* calculate negative offsets based off minmax. Fixes [#179](https://github.com/folke/noice.nvim/issues/179) ([cf2912d](https://github.com/folke/noice.nvim/commit/cf2912d08eb7442c52347d3427a61557e0783f02))
* call update_screen during cmdpreview to fix cursor movement. Fixes [#131](https://github.com/folke/noice.nvim/issues/131) ([23da4ed](https://github.com/folke/noice.nvim/commit/23da4eddea9b78ab0846c5b2a1cda5a10f49b4a4))
* check for nil on zindex. Fixes [#129](https://github.com/folke/noice.nvim/issues/129) ([07465b3](https://github.com/folke/noice.nvim/commit/07465b3486508a233701e32c948c589985d9cd48))
* check if loader returned a function before loading ([66946c7](https://github.com/folke/noice.nvim/commit/66946c72f0a36f37e480b5eae97aac3cdcd5961d))
* check if plugin is noice ([7b62ccf](https://github.com/folke/noice.nvim/commit/7b62ccfc236e51e78e5b2fc7d3068eacd65e4590))
* check item.detail is type of table ([#595](https://github.com/folke/noice.nvim/issues/595)) ([3670766](https://github.com/folke/noice.nvim/commit/3670766b10fded979fcb00606801edc585a65f2a))
* cleanup progress messages from lsp clients that died. Fixes [#175](https://github.com/folke/noice.nvim/issues/175) ([e084d3b](https://github.com/folke/noice.nvim/commit/e084d3bed43ad1372b6a638218e19c83330af403))
* **cmdline:** better and safer way to trigger redraw during cmdpreview ([02ed6d4](https://github.com/folke/noice.nvim/commit/02ed6d4c0c1e4d21fc4e79bbe54961023ee9badb))
* **cmdline:** dont use normal commands so ModeChanged will trigger correctly. Fixes [#390](https://github.com/folke/noice.nvim/issues/390) ([fa7b6a1](https://github.com/folke/noice.nvim/commit/fa7b6a18c5cdc23961038bc56b93495efcd0f5c7))
* **cmdline:** fixed a byte offset issue with the new virtual inline text ([a13a88f](https://github.com/folke/noice.nvim/commit/a13a88fb2016b6cfea8f56238566b345f537e47a))
* **cmdline:** make sure cursor is always visible ([2f0a427](https://github.com/folke/noice.nvim/commit/2f0a42701b4aa65b55fff8f32878d9adc7e7ac77))
* cmp popupmenu position ([#183](https://github.com/folke/noice.nvim/issues/183)) ([8db0420](https://github.com/folke/noice.nvim/commit/8db0420c55ea813d721f3c08c6d61ad68fb366e5))
* config.cmdline.opts now overrides any option from the cmdline formats ([2851fc2](https://github.com/folke/noice.nvim/commit/2851fc23a15a3651402ce6adfde92d0d35990e32))
* **config:** allow overriding options set by presets ([5a1bf17](https://github.com/folke/noice.nvim/commit/5a1bf1707f592fefff4cb3da903b17369e088cc1))
* **config:** correctly set the presets ([e5cb84f](https://github.com/folke/noice.nvim/commit/e5cb84f1ed524f850fa92e3a256e830ed07fadee))
* **config:** properly deal with preset routes. Fixes [#517](https://github.com/folke/noice.nvim/issues/517) ([fea7f1c](https://github.com/folke/noice.nvim/commit/fea7f1cf15b04ec9b8dd071aa3510f693156ce59))
* **confirm:** keep newlines in confirm message. Fixes [#422](https://github.com/folke/noice.nvim/issues/422) ([051111f](https://github.com/folke/noice.nvim/commit/051111f98d7128c833eaa32423426829981b2aa3))
* correctly apply padding based on four numbers ([c9c1fbd](https://github.com/folke/noice.nvim/commit/c9c1fbd605388badcfa62c0b7f58d184f19e1484))
* correctly calculate popupmenu width based on border and padding. Fixes [#122](https://github.com/folke/noice.nvim/issues/122) ([b152bf5](https://github.com/folke/noice.nvim/commit/b152bf5281a0e974b53ce1011b0938134573760e))
* **debug:** calculate stacktrace outisde of vim schedule to make it useful ([a5de1ca](https://github.com/folke/noice.nvim/commit/a5de1ca0eaecd21fd33a0a191d1a0b9dd97cb54a))
* **debug:** only concat debug info that is a string ([78ec5c6](https://github.com/folke/noice.nvim/commit/78ec5c6eefb9b61056a8545ded33b99f7a9a9f72))
* disable all signature help when signature is disabled. Fixes [#104](https://github.com/folke/noice.nvim/issues/104) ([58f52e3](https://github.com/folke/noice.nvim/commit/58f52e345d8a2fe4d9b56829986a6c5b3661fdf6))
* disable vim-sleuth for Noice buffers ([d148e1a](https://github.com/folke/noice.nvim/commit/d148e1ab5844eb0b9efa09f77772feb20cd4b660))
* disable winbar on Noice windows ([1b37f74](https://github.com/folke/noice.nvim/commit/1b37f74423bb6b2e8bf4ad3ec7f1545960f142a7))
* do render after mount Fixes [#150](https://github.com/folke/noice.nvim/issues/150) ([7e2e449](https://github.com/folke/noice.nvim/commit/7e2e4491afb02422b26c241f9fb7f8960b51fe05))
* don't try smart move between noice windows ([4a46ba3](https://github.com/folke/noice.nvim/commit/4a46ba33d8b2309d2cbcfb725e958d2e0bdc77d6))
* dont check cmdpreview on windows. Fixes [#229](https://github.com/folke/noice.nvim/issues/229) ([b10bbbb](https://github.com/folke/noice.nvim/commit/b10bbbb91215d0324d7d7f4cd0d8de3d1332648f))
* dont check lazyredraw when Noice is running ([a202a22](https://github.com/folke/noice.nvim/commit/a202a2226e91f62706ebff63a5b0d4fdf2d2e370))
* dont error if cmp not loaded when overriding ([4bae487](https://github.com/folke/noice.nvim/commit/4bae48798424d300e204cce2eb73b087854472d5))
* dont error in checkhealth if nvim-treesitter is not installed ([044767a](https://github.com/folke/noice.nvim/commit/044767a01d38208c32d97b0214cce66c41e8f7c8))
* dont hide cursor on input. Fixes [#585](https://github.com/folke/noice.nvim/issues/585). Fixes [#566](https://github.com/folke/noice.nvim/issues/566) ([819a5bf](https://github.com/folke/noice.nvim/commit/819a5bf62fa31c893c9d0c6da17ef93a810a1e8c))
* dont make scrollbars focusable ([e226401](https://github.com/folke/noice.nvim/commit/e226401ba577808528e76861edc6a04c36ccbce1))
* dont render views when not running. Fixes [#200](https://github.com/folke/noice.nvim/issues/200) ([9dc2508](https://github.com/folke/noice.nvim/commit/9dc250851eff005fe94f37c12c05bfddf2cedca8))
* dont restore cursor when exiting. Fixes [#230](https://github.com/folke/noice.nvim/issues/230) ([0115097](https://github.com/folke/noice.nvim/commit/0115097e5008bae01e512f30cea66e2d7182f19b))
* dont show if window is closed while showing. Fixes [#208](https://github.com/folke/noice.nvim/issues/208) ([a8402e8](https://github.com/folke/noice.nvim/commit/a8402e84c1923885896ee83eefb0f492a9f9b620))
* export scroll in noice.lsp. See [#161](https://github.com/folke/noice.nvim/issues/161) ([0fe5a1e](https://github.com/folke/noice.nvim/commit/0fe5a1ea053ee086327eab386594c5f2e7f15e77))
* fallback to syntax if treesitter parser is not available ([882e58c](https://github.com/folke/noice.nvim/commit/882e58c2dccce0adba30a7d483af15fbe40dd70b))
* fix lsp showMessage. Fixes [#220](https://github.com/folke/noice.nvim/issues/220) ([5ff75a5](https://github.com/folke/noice.nvim/commit/5ff75a5196d3ebe3148ca0c8c20ac750664ddfb6))
* fixed flickering during substitute & cmdpreview ([1702772](https://github.com/folke/noice.nvim/commit/170277257a976e2f669351676974a7bc51e88b5a))
* force cmdline redraw only when pum is not visible. Fixes [#188](https://github.com/folke/noice.nvim/issues/188). Closes [#189](https://github.com/folke/noice.nvim/issues/189) ([412594c](https://github.com/folke/noice.nvim/commit/412594c23090b107aeb839b49e23fc508a4e3b8b))
* guicursor behaves weird, when resetting too fast. Delay by 100ms. Fixes [#114](https://github.com/folke/noice.nvim/issues/114) ([3710528](https://github.com/folke/noice.nvim/commit/37105289ac5a4fd7b977a9c307c1a95f3e38acf6))
* **hacks:** make sure the cursor is properly updated before getchar ([0cca940](https://github.com/folke/noice.nvim/commit/0cca940561d4b723cb52ba9e4ec239fceb36f146))
* handle vim.notify nil messages for nvim-notify. Fixes [#109](https://github.com/folke/noice.nvim/issues/109) ([83b60f2](https://github.com/folke/noice.nvim/commit/83b60f2cced7428419fa41cfc30cda53082739ee))
* **health:** added info on how to disable overwritten by other plugins ([a4c3d48](https://github.com/folke/noice.nvim/commit/a4c3d484dcf925de7d27110f198c45d06cf062ac))
* **health:** allow running in GUIs with multigrid ([71a7591](https://github.com/folke/noice.nvim/commit/71a75913d680af9f1f26a2886518e390cd8f73e1))
* **health:** correctly check if lsp.message is enabled ([#381](https://github.com/folke/noice.nvim/issues/381)) ([1ff6b10](https://github.com/folke/noice.nvim/commit/1ff6b10471590331cc1585ad64f084f19cd4bcb7))
* **health:** dont use nvim-treesitter to check if a lang exists ([585d24e](https://github.com/folke/noice.nvim/commit/585d24ec6e3fb4288414f864cfe2de7d025e8216))
* **health:** fix deprecated health checks healthcheck ([#438](https://github.com/folke/noice.nvim/issues/438)) ([0f12ed3](https://github.com/folke/noice.nvim/commit/0f12ed399e79aa49f283aa954468b92be65e03ed))
* **health:** only check for lazyredraw during startup ([46a40bd](https://github.com/folke/noice.nvim/commit/46a40bde471a15d4c5bdd959327bd35aafe0030f))
* hide cursor with vim.schedule to keep Neovide from crashing ([c4ba29d](https://github.com/folke/noice.nvim/commit/c4ba29d90e15eef3603f5acb7c8526fad5092969))
* hide scroll if it was shown before. Fixes [#216](https://github.com/folke/noice.nvim/issues/216) ([f5ac589](https://github.com/folke/noice.nvim/commit/f5ac589abf503a2033e1c5b4fad40f326ccab2b4))
* **icons:** removed all obsolete icons thanks to nerdfix ([cf6a194](https://github.com/folke/noice.nvim/commit/cf6a194f9280cda1fdcc36d271fccd4a24082df3))
* improved markdown empty line handling ([8cd47e0](https://github.com/folke/noice.nvim/commit/8cd47e0080cb095f00765ef3a73e3b4e6c8fe627))
* incorrect active param for some lsp. Fixes [#162](https://github.com/folke/noice.nvim/issues/162) ([c7f1fca](https://github.com/folke/noice.nvim/commit/c7f1fca4e1a940f6964d732dfa85ac7ff0942c2d))
* keep correct case for prefix match in popupmenu ([4757fd9](https://github.com/folke/noice.nvim/commit/4757fd93160815adec33e17b8c04c762c2b12ff3))
* keep signature help open as long as the last non-whitespace character is a trigger character ([5f4544f](https://github.com/folke/noice.nvim/commit/5f4544f4e9d6481e6187d665654bcaaa19573a2e))
* let all the cmdline hl groups fallback to the default one ([040fca5](https://github.com/folke/noice.nvim/commit/040fca50b477a2eda9033860f46a5661a00ed340))
* load defaults as function to prevent require loops on older neovim versions ([48ffb9b](https://github.com/folke/noice.nvim/commit/48ffb9bfd5db6208a015b09e93472b47eabb2f08))
* **lsp:** add non-nil guard to setup function ([#454](https://github.com/folke/noice.nvim/issues/454)) ([4524216](https://github.com/folke/noice.nvim/commit/4524216d7484c7b183ca1f654d8e66dff28a5680))
* **lsp:** allow whitespace info string in markdown ([#535](https://github.com/folke/noice.nvim/issues/535)) ([1343acc](https://github.com/folke/noice.nvim/commit/1343acc592c3f138d7ffb88f9b8be1c4969b30d3))
* **lsp:** dont show lsp progress for lsp clients that died. Fixes [#207](https://github.com/folke/noice.nvim/issues/207) ([6afc974](https://github.com/folke/noice.nvim/commit/6afc9741808fb03c938afcdc5a355243ba15066b))
* **lsp:** return true if scrolling succeeded ([5750c09](https://github.com/folke/noice.nvim/commit/5750c097e7b9563ee07b83d7933f7954945f9397))
* make ffi behave with plugin reloaders ([7e78236](https://github.com/folke/noice.nvim/commit/7e782362a85132e32803bfbce77a99032abc54fd))
* make help match :help as well. Fixes [#135](https://github.com/folke/noice.nvim/issues/135) ([dc33efa](https://github.com/folke/noice.nvim/commit/dc33efa6e840eac71055d1066e54095e5c196178))
* make nui views nomodifiable ([f674f03](https://github.com/folke/noice.nvim/commit/f674f030acad42f5afd3059198fc7ad1e5e2b598))
* make search_count work with nohlsearch. Fixes [#217](https://github.com/folke/noice.nvim/issues/217) ([80ec5b8](https://github.com/folke/noice.nvim/commit/80ec5b8c5838e8583081a0bdeec5e7151c4f46d3))
* make split views behave with splitkeep and restore cursor position after re-render ([0b1fb33](https://github.com/folke/noice.nvim/commit/0b1fb33327de070f702912362578f7734ba6b5d6))
* make sure we always have an encoding for getting signatureHelp ([ba36767](https://github.com/folke/noice.nvim/commit/ba367673b3728ba2dc0672775421d13a94357dca))
* **markdown:** better check to see if a ts parser is available. Fixes [#397](https://github.com/folke/noice.nvim/issues/397) ([d60bee1](https://github.com/folke/noice.nvim/commit/d60bee1b85af1882768af80385bc2500d495feba))
* **markdown:** code block, rule, codeblock should only render one rule ([feb8e4d](https://github.com/folke/noice.nvim/commit/feb8e4d19ea6ef2a99248d608bda873e3a7d2707))
* **markdown:** conceal escaping forward slashes. Fixes [#455](https://github.com/folke/noice.nvim/issues/455) ([a7246aa](https://github.com/folke/noice.nvim/commit/a7246aa99fde34fb9d5e13c62c83ac7226514d67))
* **markdown:** replace `&lt;code&gt;`. Fixes [#424](https://github.com/folke/noice.nvim/issues/424) ([38fb652](https://github.com/folke/noice.nvim/commit/38fb652d0a95780d20a551a6ec44b01226476c99))
* **markdown:** replace additional html entities ([#448](https://github.com/folke/noice.nvim/issues/448)) ([d31fe94](https://github.com/folke/noice.nvim/commit/d31fe940e0866686718822aaac45527412c45134)), closes [#447](https://github.com/folke/noice.nvim/issues/447)
* **markdown:** revert ([d767be9](https://github.com/folke/noice.nvim/commit/d767be960e8660b19595ccff2dad6abd7aae2d4a))
* **markdown:** strip "\r" chars ([4d2801b](https://github.com/folke/noice.nvim/commit/4d2801babc4026229c58f0c77a20ff5b7b4c0d07))
* mini focusable=false by default ([04794f6](https://github.com/folke/noice.nvim/commit/04794f6d1ea2be83bcc5617c78aa7b7fab46fcdd))
* noautocmd for ze in cmdline. Fixes [#206](https://github.com/folke/noice.nvim/issues/206) ([8d088aa](https://github.com/folke/noice.nvim/commit/8d088aa6083d0332ced778aab0e1fa2f2533902c))
* **notify_send:** properly close file descriptors from spwaning notifysend ([f5132fa](https://github.com/folke/noice.nvim/commit/f5132fa6eb71e96d9f0cd7148b186b324b142d15))
* **notify:** better way of finding rendering offset. Fixes [#181](https://github.com/folke/noice.nvim/issues/181) ([dbadd10](https://github.com/folke/noice.nvim/commit/dbadd106e42b6344243405614ae3583fb5b17efe))
* **notify:** nvim-notify replace can be an id or a record ([a9cc87b](https://github.com/folke/noice.nvim/commit/a9cc87b14e18bc3717746b45d79157c0adb43a4d))
* **notify:** take col offsets into account for nvim-notify renderers. Fixes [#375](https://github.com/folke/noice.nvim/issues/375) ([20596d9](https://github.com/folke/noice.nvim/commit/20596d96551605f7462f5722198b188e4047b605))
* nui windows must have nowrap by default. See [#196](https://github.com/folke/noice.nvim/issues/196) ([48003c5](https://github.com/folke/noice.nvim/commit/48003c550a03bd15169b35c5b3dc066f0e8f541d))
* nui.menu._tree -&gt; nui.menu.tree ([ab151eb](https://github.com/folke/noice.nvim/commit/ab151eb85b15d13176d1b2a4c37113530637a058))
* **nui:** dont trigger autocmds when doing zt ([d176765](https://github.com/folke/noice.nvim/commit/d176765ceabae9a12bf09a5c785d3dcb3859e1b6))
* **nui:** make sure nui recreates buffer and window when needed ([3e6dfd8](https://github.com/folke/noice.nvim/commit/3e6dfd8bb00d98399704a020ab7892234ce80fdb))
* **nui:** mount if buffer is no longer valid ([71d7b5c](https://github.com/folke/noice.nvim/commit/71d7b5cf8f24b9bdc425934c36cfda784fcd10f2))
* **nui:** nui broke noice. added a temporary work-around till the problem is solved ([4db3c8f](https://github.com/folke/noice.nvim/commit/4db3c8f14302273b842f73a8facf1999169c1e41))
* **nui:** remove border text when style is `nil`, `"none"`, or `"shadow"` ([d85a4d0](https://github.com/folke/noice.nvim/commit/d85a4d01774b5649dbcda8526a26f201dff5ade4))
* **nui:** remove padding when border is `shadow` ([1515007](https://github.com/folke/noice.nvim/commit/151500759722c12fb6a3931c5243d68f01af007a))
* **nui:** removed work-around for padding and border style shadow ([4f34d33](https://github.com/folke/noice.nvim/commit/4f34d33fc3dc0d6f4da9b4b8c63b9714fd4eea79))
* **nui:** reset close events on remount ([1558c48](https://github.com/folke/noice.nvim/commit/1558c48257e6d1c99edd15fd12fbd1dbc4fa22c1))
* **nui:** set mounted=false if buffer is no longer valid ([3353a7a](https://github.com/folke/noice.nvim/commit/3353a7ab4bae6c22f61fd646c10e336b4582f0ea))
* **nui:** umount on hide, to fix rendering issue while blocking ([119682b](https://github.com/folke/noice.nvim/commit/119682b44f6b5303e141fdbdbdd25c261a89d306))
* one-off error for highlighting with treesitter/syntax ([1602ce8](https://github.com/folke/noice.nvim/commit/1602ce897e66672c43da95c9175d103f1a69e2aa))
* only relayout with real width and height ([2462809](https://github.com/folke/noice.nvim/commit/24628097307e5e8453e691192bed45ec6da1bebd))
* only set noice buffer names if debug. Fixes [#197](https://github.com/folke/noice.nvim/issues/197) ([ea1079d](https://github.com/folke/noice.nvim/commit/ea1079deb6ffdc326b3da0dc2e84371b330dfdae))
* only show/hide scrollbar when needed ([d01cd10](https://github.com/folke/noice.nvim/commit/d01cd1052a865588bbebbd4015ad778b81312fe9))
* **overrides:** noice was leaking extmarks for stylize_markdown ([9b148a1](https://github.com/folke/noice.nvim/commit/9b148a141df7fefc66705e2e7219d11536b99288))
* popupmenu default relative=editor ([7ef41aa](https://github.com/folke/noice.nvim/commit/7ef41aa92e2ca0bdfe972bc6a68350c8be06044e))
* **popupmenu:** always show the regular (non-cmdline) popupmenu near the cursor ([e3936cc](https://github.com/folke/noice.nvim/commit/e3936ccbbd32f6ce4a4f55a77ec556b116c0b928))
* **popupmenu:** only use popupmenu hl group for known item kinds. Fixes [#453](https://github.com/folke/noice.nvim/issues/453) ([0b86a7b](https://github.com/folke/noice.nvim/commit/0b86a7bfbf84927909ed81e9616a5e24602fe6fb))
* **popupmenu:** properly close pmenu when cmdline window is open. Fixes [#542](https://github.com/folke/noice.nvim/issues/542) ([d19e5cb](https://github.com/folke/noice.nvim/commit/d19e5cb58e33c6d74e9005d1965d6e8ebd6b057b))
* **popupmenu:** replace any newlines by space. Fixes [#265](https://github.com/folke/noice.nvim/issues/265) ([5199089](https://github.com/folke/noice.nvim/commit/51990892e1dd5ee1a1444b1cf3ccf0aca377e0c4))
* potential endless loop in markdown key handlers ([078cbd9](https://github.com/folke/noice.nvim/commit/078cbd9087fd358df8de54072253c0e2ae7c89c9))
* **preset:** palette now configures cmdline_popupmenu instead of popupmenu ([294097a](https://github.com/folke/noice.nvim/commit/294097a239ec943587e5707b678142c52a9b318e))
* progress use vim.lsp.get_client_by_id ([#529](https://github.com/folke/noice.nvim/issues/529)) ([397619d](https://github.com/folke/noice.nvim/commit/397619d5351d650e9879d18c9312a5add5729815))
* properly handle carriage returns. Fixes [#190](https://github.com/folke/noice.nvim/issues/190) ([c14b064](https://github.com/folke/noice.nvim/commit/c14b0649c2356a4e86aeea63449859ee0b39ef6d))
* properly handle MarkedString[] mix. Fixes [#178](https://github.com/folke/noice.nvim/issues/178) ([14cff19](https://github.com/folke/noice.nvim/commit/14cff1957fe00ec8f6d2d0951369bbccad74c7c2))
* re-use existing views with same backend and opts ([1d1e9ed](https://github.com/folke/noice.nvim/commit/1d1e9ed9ce34895c7dfb80d44aa5b7a90863ef06))
* read conceal setting after sort ([#558](https://github.com/folke/noice.nvim/issues/558)) ([24c09cc](https://github.com/folke/noice.nvim/commit/24c09cc0263054cb3d8dedf2c54b570e655850f5))
* reduce some flickering when updating views ([f39b657](https://github.com/folke/noice.nvim/commit/f39b657bff3d224b41fbe6b21fd3ce24e6b9b4e2))
* remove old neovide compatibility warning ([#545](https://github.com/folke/noice.nvim/issues/545)) ([dfbe27c](https://github.com/folke/noice.nvim/commit/dfbe27cfafd6bcb5605dc6c6b82174c33fc9b09e))
* reopen scrollbar windows if they were deleted somehow. Fixes [#235](https://github.com/folke/noice.nvim/issues/235) ([74c7e29](https://github.com/folke/noice.nvim/commit/74c7e29aba2cc32e5a51fa1828813e08f327ef3a))
* reset preloader before trying to load the module ([08655e9](https://github.com/folke/noice.nvim/commit/08655e9f1bed638f9871d76b05928da74d1eeb68))
* reset view when update_layout fails. Fixes [#155](https://github.com/folke/noice.nvim/issues/155) ([7d08ed5](https://github.com/folke/noice.nvim/commit/7d08ed5bcc2d4a5fc540f096dd1d8fa800faed42))
* restore cursor with vim.schedule to be safe ([973659e](https://github.com/folke/noice.nvim/commit/973659e01fafa5b8e5808dce443bfddb63e5eb54))
* return lines in stylize_markdown ([f9bf77d](https://github.com/folke/noice.nvim/commit/f9bf77ddd5d6d78c37391696e05ba6e7d0c9830f))
* return message id in vim.notify, so it can be used for replace if the view supports it. Fixes [#109](https://github.com/folke/noice.nvim/issues/109) ([0b0e8cf](https://github.com/folke/noice.nvim/commit/0b0e8cf85ab5fcb891b7cfd44c0c4908c0e1ef46))
* return nil when Noice is not running for statusline ([289ce14](https://github.com/folke/noice.nvim/commit/289ce145dca5300f9a30684221b9ebe375bb4aae))
* **router:** properly disable updater when disabling Noice. Fixes [#423](https://github.com/folke/noice.nvim/issues/423) ([3bed83b](https://github.com/folke/noice.nvim/commit/3bed83b4d2e4fce03a27071c39be0d9e04313332))
* scroll cmdline to make sure cursor is always visible. Fixes [#196](https://github.com/folke/noice.nvim/issues/196) ([e023c5f](https://github.com/folke/noice.nvim/commit/e023c5f005807e8bbcab2d1f614e75a9f62edc59))
* scrollbar destructs itself, so make a copy to see if there are any remnants left ([8d80a69](https://github.com/folke/noice.nvim/commit/8d80a692d5a045a3ec995536782f2b4c2b8d901b))
* scrollbar for popups was off if there was padding on the window ([deda89a](https://github.com/folke/noice.nvim/commit/deda89a17c1e9dc1d4886b4c1d3704dfddefb1f2))
* **scrollbar:** zindex + 1 + 2 for bar and thumb ([0daa539](https://github.com/folke/noice.nvim/commit/0daa5390eb14e0c19ac64debaea638bcf5fb70aa))
* set conceallevel local. Fixes [#634](https://github.com/folke/noice.nvim/issues/634) ([c1591df](https://github.com/folke/noice.nvim/commit/c1591dfc8e2177402eff82be5c9cddc72de28c16))
* set cursor to top when opening view. Fixes [#165](https://github.com/folke/noice.nvim/issues/165) ([c20f38e](https://github.com/folke/noice.nvim/commit/c20f38e7c1b6d368af2bb599667b473879316c89))
* show unstable message after loading noice ([2613a16](https://github.com/folke/noice.nvim/commit/2613a16b5009acbf2adabb34b029b1c4c57101e3))
* showMessage error with kinds. Fixes [#222](https://github.com/folke/noice.nvim/issues/222) ([d4d653a](https://github.com/folke/noice.nvim/commit/d4d653a894d1f1fbc422db1f8351d86fdb1f16f8))
* **signature:** nil check for parameter label. Fixes [#435](https://github.com/folke/noice.nvim/issues/435) ([9d778e7](https://github.com/folke/noice.nvim/commit/9d778e7ce29c519ca0285b054e7c3b679bc9d3b9))
* **signature:** nil check on lsp signature.parameters. Fixes [#162](https://github.com/folke/noice.nvim/issues/162) ([1dc7f26](https://github.com/folke/noice.nvim/commit/1dc7f26a68efbd5f0da081d98d938c587de0ba25))
* **signature:** safer lsp signature parameters ([#449](https://github.com/folke/noice.nvim/issues/449)) ([e33c346](https://github.com/folke/noice.nvim/commit/e33c34642a7b02db3db03bfc2bec7799bbc2034e))
* **signature:** show signature in correct window. Fixes [#593](https://github.com/folke/noice.nvim/issues/593) ([2f0993e](https://github.com/folke/noice.nvim/commit/2f0993ee97f98cacde179a1f431881b2758e2138))
* **signature:** support label offsets ([9649d9f](https://github.com/folke/noice.nvim/commit/9649d9fd4d8fa8a8654e1e9c293718ae8d62e73b))
* **signature:** when loading, attach to existing lsp clients. Fixes [#342](https://github.com/folke/noice.nvim/issues/342) ([f69f1a5](https://github.com/folke/noice.nvim/commit/f69f1a577615a5a6527f133df0aa40e596bd1707))
* silence treesitter errors of invalid langs. Covered by checkhealth ([db1628f](https://github.com/folke/noice.nvim/commit/db1628fc81cf2029eea9dfe2e8e121143b6b35dc))
* **smart_move:** Dont move `cmdline` view ([#123](https://github.com/folke/noice.nvim/issues/123)) ([3da3f6d](https://github.com/folke/noice.nvim/commit/3da3f6d5be613ff7eb590c3e7f31c4e0cddf75d8))
* statusline messages no longer need active state. Fixes [#211](https://github.com/folke/noice.nvim/issues/211) ([e5092c2](https://github.com/folke/noice.nvim/commit/e5092c284a6ffd44e8d09f5efbe29395190c77f9))
* stop processing messages when Neovim is exiting. Fixes [#237](https://github.com/folke/noice.nvim/issues/237) ([8c8acf7](https://github.com/folke/noice.nvim/commit/8c8acf74c09374e48a8fa1835560c3913d57243f))
* support older Neovim versions ([4a1ec5e](https://github.com/folke/noice.nvim/commit/4a1ec5ec0b163a365d7593d93450676b9cbcbebd))
* **swap:** additionally check for updates when a swap file was found ([1165d3e](https://github.com/folke/noice.nvim/commit/1165d3e727bdd226eefffcc801d563bcb30e71c4))
* tag popupmenu border ([d2064a5](https://github.com/folke/noice.nvim/commit/d2064a50495f21f14ce52419660672f1e7c489bf))
* tag scrollbar and popupmenu ([13bed57](https://github.com/folke/noice.nvim/commit/13bed5763abd9a0c4c84abd794f26772cb850fe8))
* **telescope:** Correct index for finder ([#136](https://github.com/folke/noice.nvim/issues/136)) ([99bbfe7](https://github.com/folke/noice.nvim/commit/99bbfe7ee49263577f6a941ad61677199a02eaf7))
* **telescope:** wrap text in telescope's previewer ([#514](https://github.com/folke/noice.nvim/issues/514)) ([a7f611e](https://github.com/folke/noice.nvim/commit/a7f611ef740a45b995d4a8e6d237643ac6ad0093))
* **text:** better (correct) way of dealing with `\r` characters. Fixes [#483](https://github.com/folke/noice.nvim/issues/483) ([520a737](https://github.com/folke/noice.nvim/commit/520a73760030f1293bbee41b0dcd041f47d1ecae))
* **text:** temp fixup for CRLF handling ([3e1400f](https://github.com/folke/noice.nvim/commit/3e1400f172cf67041f6845d86413de56fb90e685))
* **treesitter:** deprecated call. Fixes [#408](https://github.com/folke/noice.nvim/issues/408) ([1ded575](https://github.com/folke/noice.nvim/commit/1ded575928752861558a729fcbbd1e6e53c76652))
* **treesitter:** dont allow recursive injections. Fixes [#286](https://github.com/folke/noice.nvim/issues/286) ([a31b41a](https://github.com/folke/noice.nvim/commit/a31b41a739731988fc30a48a3099586a884bdf61))
* **treesitter:** fixed treesitter.query.get. Fixes [#539](https://github.com/folke/noice.nvim/issues/539) ([e91a31c](https://github.com/folke/noice.nvim/commit/e91a31c32c0eef6a338030ac51eaed14ac49ce2e))
* **treesitter:** ignore weird invalid end_col errors. Fixes [#473](https://github.com/folke/noice.nvim/issues/473) ([7e2692b](https://github.com/folke/noice.nvim/commit/7e2692b0c461da182a54ff2af4a35aea2bf8ea5c))
* **treesitter:** only disable injections for php and html ([0e1bf11](https://github.com/folke/noice.nvim/commit/0e1bf11d46054b8ab04eb62b53c5ac81b44f14df))
* **treesitter:** parse injections ([#571](https://github.com/folke/noice.nvim/issues/571)) ([3ec6e42](https://github.com/folke/noice.nvim/commit/3ec6e4221e9b80f914ed6774abb4e82d8f5c3b39))
* **treesitter:** use the new treesitter ft to lang API if availble. Fixes [#378](https://github.com/folke/noice.nvim/issues/378) ([36d141b](https://github.com/folke/noice.nvim/commit/36d141bd5852b10e32058e259982182b9e5e8060))
* truncate log file if it becomes too big ([79a5262](https://github.com/folke/noice.nvim/commit/79a526210233808e7c73714998f56c9f059c11d8))
* **ui_attach:** dont update router during `ext_messages` and disable/enable Noice during confirm. [#298](https://github.com/folke/noice.nvim/issues/298) ([a4cbc0f](https://github.com/folke/noice.nvim/commit/a4cbc0f0cebdaa9529a749f4463aedc5a2cdcf1b))
* **ui:** cmdline is always blocking. Fixes [#347](https://github.com/folke/noice.nvim/issues/347) ([6702d97](https://github.com/folke/noice.nvim/commit/6702d97d3c37c3a363ffc7c890578109f82f9f20))
* **ui:** disable debug logging ([bfb0cdb](https://github.com/folke/noice.nvim/commit/bfb0cdb56cc3b2eb5f00b6c1747d04540d76799a))
* **ui:** dont propagate events handled by Noice to other uis. Fixes [#17](https://github.com/folke/noice.nvim/issues/17) ([1cff24c](https://github.com/folke/noice.nvim/commit/1cff24cabf1076916be1e83de16514be99827678))
* **ui:** dont update on msg_ruler. Fixes [#588](https://github.com/folke/noice.nvim/issues/588) ([ec19fc0](https://github.com/folke/noice.nvim/commit/ec19fc0fd27fcfa8661d71bcfb61f6b84a6b7f98))
* **ui:** exclude search_count from realtime updates ([73caffa](https://github.com/folke/noice.nvim/commit/73caffa74550e98ae3f61520a4af526ac593609b))
* **ui:** safer adding of winhl ([36b1935](https://github.com/folke/noice.nvim/commit/36b1935660988b4b6034ef9fb8454a1427990675))
* **ui:** work-around for segfaults in TUI. Fixes [#298](https://github.com/folke/noice.nvim/issues/298) ([176ec31](https://github.com/folke/noice.nvim/commit/176ec31026ec4baf64638fba1a180701257380f1))
* use modeline=false for popupmenu scroll events. Fixes [#572](https://github.com/folke/noice.nvim/issues/572) ([1f087c2](https://github.com/folke/noice.nvim/commit/1f087c2495bbc824b556329eb389dfff8964e5a3))
* use vim.F.unpack_len and vim.F.pack_len. Fixes a number of issues... ([51c2179](https://github.com/folke/noice.nvim/commit/51c2179d3535d4c61d0ceb80e2938884fa73181c))
* **views:** don't override winbar and foldenable for every view ([a7d60f7](https://github.com/folke/noice.nvim/commit/a7d60f73b1325137b34c630bc0af76fa6598ba1f))
* **views:** dont highlight CurSearch for some views. Fixes [#399](https://github.com/folke/noice.nvim/issues/399) ([0c493e5](https://github.com/folke/noice.nvim/commit/0c493e5d243c39adf3d6ce7683a16e610cc44e0a))
* **views:** increase zindex for cmdline popup, popupmenu and confirm from 60 to 200 ([d71c1de](https://github.com/folke/noice.nvim/commit/d71c1deabf78db16262f5388fe12930fc16bd93e))
* **virtual:** extra check if buffer still valid that has virtual text extmark ([7ed897d](https://github.com/folke/noice.nvim/commit/7ed897d77d13eb4a9f4ab576f58db9bdda9af6ec))
* **virtual:** remove extmark from correct buffer where it was set. Fixes [#464](https://github.com/folke/noice.nvim/issues/464) ([e5a4c7a](https://github.com/folke/noice.nvim/commit/e5a4c7a6ac3ef4c32f97a50c0b9b21e21c445c04))
* wait to override cmp till it loaded ([712180f](https://github.com/folke/noice.nvim/commit/712180f94684b7ce56957df60d037c81784e69c3))
* workaround E36: Not enough room errors ([#522](https://github.com/folke/noice.nvim/issues/522)) ([f43775f](https://github.com/folke/noice.nvim/commit/f43775f0e427b0c7e9d30e6bc51fdebea6979b37))


### Performance Improvements

* cache highlighter queries ([b4eb215](https://github.com/folke/noice.nvim/commit/b4eb2155f3347377eb0c14458755ce7b7966cdb7))
* do redrawstatus before resetting cursor ([5aa862f](https://github.com/folke/noice.nvim/commit/5aa862f380c65fbe2833b2b9e869822e7e9f8257))
* don't bufload when highlighting a buffer ([8df4cbd](https://github.com/folke/noice.nvim/commit/8df4cbdae15a915d460828710bf9ff1befb3f12d))
* dont update popupmenu state when it hasn't changed ([cafdddb](https://github.com/folke/noice.nvim/commit/cafdddb6eb3105cac1220337f91c21aebe998485))
* **lazy:** set package.loaded when real module was loaded ([f6cc07a](https://github.com/folke/noice.nvim/commit/f6cc07af4d9329c48fed9e22044f2a0ed8ac7d31))
* make noice a bit more robust when exiting to prevent possible delays on exit ([35e3664](https://github.com/folke/noice.nvim/commit/35e3664297096d8e24ca17f590bc793482f5182d))
* **popupmenu:** re-use existing nui menu for rendering the popupmenu ([fdd78c2](https://github.com/folke/noice.nvim/commit/fdd78c25f64482c4c92ca84ba9c5814a5aa2788e))
* re-use existing popupmenu instead of unmount/create ([b209e0b](https://github.com/folke/noice.nvim/commit/b209e0bbb1666081eb70cfa919d315d892e73cb7))
* shutdown Noice on VimLeave to prevent close delay ([de1d5dc](https://github.com/folke/noice.nvim/commit/de1d5dc1f9446221674cee6b69b81a28b13dfa62))

## [1.16.3](https://github.com/folke/noice.nvim/compare/v1.16.2...v1.16.3) (2023-10-24)


### Bug Fixes

* **hacks:** make sure the cursor is properly updated before getchar ([0cca940](https://github.com/folke/noice.nvim/commit/0cca940561d4b723cb52ba9e4ec239fceb36f146))
* use modeline=false for popupmenu scroll events. Fixes [#572](https://github.com/folke/noice.nvim/issues/572) ([1f087c2](https://github.com/folke/noice.nvim/commit/1f087c2495bbc824b556329eb389dfff8964e5a3))

## [1.16.2](https://github.com/folke/noice.nvim/compare/v1.16.1...v1.16.2) (2023-10-15)


### Bug Fixes

* **cmdline:** better and safer way to trigger redraw during cmdpreview ([02ed6d4](https://github.com/folke/noice.nvim/commit/02ed6d4c0c1e4d21fc4e79bbe54961023ee9badb))
* **signature:** show signature in correct window. Fixes [#593](https://github.com/folke/noice.nvim/issues/593) ([2f0993e](https://github.com/folke/noice.nvim/commit/2f0993ee97f98cacde179a1f431881b2758e2138))
* **virtual:** extra check if buffer still valid that has virtual text extmark ([7ed897d](https://github.com/folke/noice.nvim/commit/7ed897d77d13eb4a9f4ab576f58db9bdda9af6ec))
* **virtual:** remove extmark from correct buffer where it was set. Fixes [#464](https://github.com/folke/noice.nvim/issues/464) ([e5a4c7a](https://github.com/folke/noice.nvim/commit/e5a4c7a6ac3ef4c32f97a50c0b9b21e21c445c04))

## [1.16.1](https://github.com/folke/noice.nvim/compare/v1.16.0...v1.16.1) (2023-10-07)


### Bug Fixes

* **ui:** exclude search_count from realtime updates ([73caffa](https://github.com/folke/noice.nvim/commit/73caffa74550e98ae3f61520a4af526ac593609b))

## [1.16.0](https://github.com/folke/noice.nvim/compare/v1.15.11...v1.16.0) (2023-10-04)


### Features

* Support hide scrollbar for view ([#603](https://github.com/folke/noice.nvim/issues/603)) ([f700175](https://github.com/folke/noice.nvim/commit/f700175b91948e4f71cf73872cea364247cf2dbd))


### Bug Fixes

* **ui:** disable debug logging ([bfb0cdb](https://github.com/folke/noice.nvim/commit/bfb0cdb56cc3b2eb5f00b6c1747d04540d76799a))
* **ui:** dont update on msg_ruler. Fixes [#588](https://github.com/folke/noice.nvim/issues/588) ([ec19fc0](https://github.com/folke/noice.nvim/commit/ec19fc0fd27fcfa8661d71bcfb61f6b84a6b7f98))

## [1.15.11](https://github.com/folke/noice.nvim/compare/v1.15.10...v1.15.11) (2023-09-25)


### Bug Fixes

* accept preset as a table ([#582](https://github.com/folke/noice.nvim/issues/582)) ([53d613c](https://github.com/folke/noice.nvim/commit/53d613cd0031e83987964947b1bad8b5047c9d0e))
* check item.detail is type of table ([#595](https://github.com/folke/noice.nvim/issues/595)) ([3670766](https://github.com/folke/noice.nvim/commit/3670766b10fded979fcb00606801edc585a65f2a))
* dont hide cursor on input. Fixes [#585](https://github.com/folke/noice.nvim/issues/585). Fixes [#566](https://github.com/folke/noice.nvim/issues/566) ([819a5bf](https://github.com/folke/noice.nvim/commit/819a5bf62fa31c893c9d0c6da17ef93a810a1e8c))
* read conceal setting after sort ([#558](https://github.com/folke/noice.nvim/issues/558)) ([24c09cc](https://github.com/folke/noice.nvim/commit/24c09cc0263054cb3d8dedf2c54b570e655850f5))

## [1.15.10](https://github.com/folke/noice.nvim/compare/v1.15.9...v1.15.10) (2023-08-26)


### Bug Fixes

* **treesitter:** parse injections ([#571](https://github.com/folke/noice.nvim/issues/571)) ([3ec6e42](https://github.com/folke/noice.nvim/commit/3ec6e4221e9b80f914ed6774abb4e82d8f5c3b39))

## [1.15.9](https://github.com/folke/noice.nvim/compare/v1.15.8...v1.15.9) (2023-07-25)


### Bug Fixes

* **health:** allow running in GUIs with multigrid ([71a7591](https://github.com/folke/noice.nvim/commit/71a75913d680af9f1f26a2886518e390cd8f73e1))

## [1.15.8](https://github.com/folke/noice.nvim/compare/v1.15.7...v1.15.8) (2023-07-21)


### Bug Fixes

* remove old neovide compatibility warning ([#545](https://github.com/folke/noice.nvim/issues/545)) ([dfbe27c](https://github.com/folke/noice.nvim/commit/dfbe27cfafd6bcb5605dc6c6b82174c33fc9b09e))

## [1.15.7](https://github.com/folke/noice.nvim/compare/v1.15.6...v1.15.7) (2023-07-20)


### Bug Fixes

* **popupmenu:** properly close pmenu when cmdline window is open. Fixes [#542](https://github.com/folke/noice.nvim/issues/542) ([d19e5cb](https://github.com/folke/noice.nvim/commit/d19e5cb58e33c6d74e9005d1965d6e8ebd6b057b))

## [1.15.6](https://github.com/folke/noice.nvim/compare/v1.15.5...v1.15.6) (2023-07-18)


### Bug Fixes

* **treesitter:** fixed treesitter.query.get. Fixes [#539](https://github.com/folke/noice.nvim/issues/539) ([e91a31c](https://github.com/folke/noice.nvim/commit/e91a31c32c0eef6a338030ac51eaed14ac49ce2e))

## [1.15.5](https://github.com/folke/noice.nvim/compare/v1.15.4...v1.15.5) (2023-07-17)


### Bug Fixes

* **lsp:** allow whitespace info string in markdown ([#535](https://github.com/folke/noice.nvim/issues/535)) ([1343acc](https://github.com/folke/noice.nvim/commit/1343acc592c3f138d7ffb88f9b8be1c4969b30d3))
* **ui:** dont propagate events handled by Noice to other uis. Fixes [#17](https://github.com/folke/noice.nvim/issues/17) ([1cff24c](https://github.com/folke/noice.nvim/commit/1cff24cabf1076916be1e83de16514be99827678))

## [1.15.4](https://github.com/folke/noice.nvim/compare/v1.15.3...v1.15.4) (2023-06-30)


### Bug Fixes

* progress use vim.lsp.get_client_by_id ([#529](https://github.com/folke/noice.nvim/issues/529)) ([397619d](https://github.com/folke/noice.nvim/commit/397619d5351d650e9879d18c9312a5add5729815))
* workaround E36: Not enough room errors ([#522](https://github.com/folke/noice.nvim/issues/522)) ([f43775f](https://github.com/folke/noice.nvim/commit/f43775f0e427b0c7e9d30e6bc51fdebea6979b37))

## [1.15.3](https://github.com/folke/noice.nvim/compare/v1.15.2...v1.15.3) (2023-06-24)


### Bug Fixes

* **config:** properly deal with preset routes. Fixes [#517](https://github.com/folke/noice.nvim/issues/517) ([fea7f1c](https://github.com/folke/noice.nvim/commit/fea7f1cf15b04ec9b8dd071aa3510f693156ce59))

## [1.15.2](https://github.com/folke/noice.nvim/compare/v1.15.1...v1.15.2) (2023-06-22)


### Bug Fixes

* **telescope:** wrap text in telescope's previewer ([#514](https://github.com/folke/noice.nvim/issues/514)) ([a7f611e](https://github.com/folke/noice.nvim/commit/a7f611ef740a45b995d4a8e6d237643ac6ad0093))
* **views:** don't override winbar and foldenable for every view ([a7d60f7](https://github.com/folke/noice.nvim/commit/a7d60f73b1325137b34c630bc0af76fa6598ba1f))
* **views:** increase zindex for cmdline popup, popupmenu and confirm from 60 to 200 ([d71c1de](https://github.com/folke/noice.nvim/commit/d71c1deabf78db16262f5388fe12930fc16bd93e))

## [1.15.1](https://github.com/folke/noice.nvim/compare/v1.15.0...v1.15.1) (2023-06-10)


### Bug Fixes

* **nui:** nui broke noice. added a temporary work-around till the problem is solved ([4db3c8f](https://github.com/folke/noice.nvim/commit/4db3c8f14302273b842f73a8facf1999169c1e41))
* **ui:** safer adding of winhl ([36b1935](https://github.com/folke/noice.nvim/commit/36b1935660988b4b6034ef9fb8454a1427990675))

## [1.15.0](https://github.com/folke/noice.nvim/compare/v1.14.2...v1.15.0) (2023-06-06)


### Features

* add `circleFull` spinner ([#495](https://github.com/folke/noice.nvim/issues/495)) ([5427398](https://github.com/folke/noice.nvim/commit/54273980749ceb4396501300bf4c86f3bb818f75))
* **popupmenu:** allow different views for regular/cmdline popupmenu ([af706c4](https://github.com/folke/noice.nvim/commit/af706c4b443cf1c416ef7288ec3434f3f1ab6cf1))


### Bug Fixes

* **popupmenu:** always show the regular (non-cmdline) popupmenu near the cursor ([e3936cc](https://github.com/folke/noice.nvim/commit/e3936ccbbd32f6ce4a4f55a77ec556b116c0b928))
* **preset:** palette now configures cmdline_popupmenu instead of popupmenu ([294097a](https://github.com/folke/noice.nvim/commit/294097a239ec943587e5707b678142c52a9b318e))


### Performance Improvements

* **popupmenu:** re-use existing nui menu for rendering the popupmenu ([fdd78c2](https://github.com/folke/noice.nvim/commit/fdd78c25f64482c4c92ca84ba9c5814a5aa2788e))

## [1.14.2](https://github.com/folke/noice.nvim/compare/v1.14.1...v1.14.2) (2023-05-27)


### Bug Fixes

* **block:** better deal with carriage return characters (take 2) ([ee24b36](https://github.com/folke/noice.nvim/commit/ee24b36743b18e53bdc6b49bbfa426fc18ea337a))
* **text:** temp fixup for CRLF handling ([3e1400f](https://github.com/folke/noice.nvim/commit/3e1400f172cf67041f6845d86413de56fb90e685))

## [1.14.1](https://github.com/folke/noice.nvim/compare/v1.14.0...v1.14.1) (2023-05-27)


### Bug Fixes

* **text:** better (correct) way of dealing with `\r` characters. Fixes [#483](https://github.com/folke/noice.nvim/issues/483) ([520a737](https://github.com/folke/noice.nvim/commit/520a73760030f1293bbee41b0dcd041f47d1ecae))

## [1.14.0](https://github.com/folke/noice.nvim/compare/v1.13.4...v1.14.0) (2023-05-25)


### Features

* **cmdline:** added support for FloatTitle and added proper default ([79c7059](https://github.com/folke/noice.nvim/commit/79c70594aefb4efecbce4528174fdd0227baaf3e))

## [1.13.4](https://github.com/folke/noice.nvim/compare/v1.13.3...v1.13.4) (2023-05-24)


### Bug Fixes

* **cmdline:** fixed a byte offset issue with the new virtual inline text ([a13a88f](https://github.com/folke/noice.nvim/commit/a13a88fb2016b6cfea8f56238566b345f537e47a))

## [1.13.3](https://github.com/folke/noice.nvim/compare/v1.13.2...v1.13.3) (2023-05-24)


### Bug Fixes

* **overrides:** noice was leaking extmarks for stylize_markdown ([9b148a1](https://github.com/folke/noice.nvim/commit/9b148a141df7fefc66705e2e7219d11536b99288))

## [1.13.2](https://github.com/folke/noice.nvim/compare/v1.13.1...v1.13.2) (2023-05-22)


### Bug Fixes

* **treesitter:** ignore weird invalid end_col errors. Fixes [#473](https://github.com/folke/noice.nvim/issues/473) ([7e2692b](https://github.com/folke/noice.nvim/commit/7e2692b0c461da182a54ff2af4a35aea2bf8ea5c))


### Performance Improvements

* don't bufload when highlighting a buffer ([8df4cbd](https://github.com/folke/noice.nvim/commit/8df4cbdae15a915d460828710bf9ff1befb3f12d))

## [1.13.1](https://github.com/folke/noice.nvim/compare/v1.13.0...v1.13.1) (2023-05-21)


### Bug Fixes

* support older Neovim versions ([4a1ec5e](https://github.com/folke/noice.nvim/commit/4a1ec5ec0b163a365d7593d93450676b9cbcbebd))

## [1.13.0](https://github.com/folke/noice.nvim/compare/v1.12.4...v1.13.0) (2023-05-21)


### Features

* **cmp:** incude item.detail when it's not part of item.documentation ([c2a745a](https://github.com/folke/noice.nvim/commit/c2a745a26ae562f1faecbf6177ac53377d2658d5))


### Bug Fixes

* **notify:** nvim-notify replace can be an id or a record ([a9cc87b](https://github.com/folke/noice.nvim/commit/a9cc87b14e18bc3717746b45d79157c0adb43a4d))


### Performance Improvements

* cache highlighter queries ([b4eb215](https://github.com/folke/noice.nvim/commit/b4eb2155f3347377eb0c14458755ce7b7966cdb7))

## [1.12.4](https://github.com/folke/noice.nvim/compare/v1.12.3...v1.12.4) (2023-05-07)


### Bug Fixes

* **lsp:** add non-nil guard to setup function ([#454](https://github.com/folke/noice.nvim/issues/454)) ([4524216](https://github.com/folke/noice.nvim/commit/4524216d7484c7b183ca1f654d8e66dff28a5680))
* **markdown:** conceal escaping forward slashes. Fixes [#455](https://github.com/folke/noice.nvim/issues/455) ([a7246aa](https://github.com/folke/noice.nvim/commit/a7246aa99fde34fb9d5e13c62c83ac7226514d67))

## [1.12.3](https://github.com/folke/noice.nvim/compare/v1.12.2...v1.12.3) (2023-05-04)


### Bug Fixes

* **health:** fix deprecated health checks healthcheck ([#438](https://github.com/folke/noice.nvim/issues/438)) ([0f12ed3](https://github.com/folke/noice.nvim/commit/0f12ed399e79aa49f283aa954468b92be65e03ed))
* **markdown:** replace additional html entities ([#448](https://github.com/folke/noice.nvim/issues/448)) ([d31fe94](https://github.com/folke/noice.nvim/commit/d31fe940e0866686718822aaac45527412c45134)), closes [#447](https://github.com/folke/noice.nvim/issues/447)
* **popupmenu:** only use popupmenu hl group for known item kinds. Fixes [#453](https://github.com/folke/noice.nvim/issues/453) ([0b86a7b](https://github.com/folke/noice.nvim/commit/0b86a7bfbf84927909ed81e9616a5e24602fe6fb))
* **signature:** safer lsp signature parameters ([#449](https://github.com/folke/noice.nvim/issues/449)) ([e33c346](https://github.com/folke/noice.nvim/commit/e33c34642a7b02db3db03bfc2bec7799bbc2034e))

## [1.12.2](https://github.com/folke/noice.nvim/compare/v1.12.1...v1.12.2) (2023-04-18)


### Bug Fixes

* **signature:** nil check for parameter label. Fixes [#435](https://github.com/folke/noice.nvim/issues/435) ([9d778e7](https://github.com/folke/noice.nvim/commit/9d778e7ce29c519ca0285b054e7c3b679bc9d3b9))
* **signature:** support label offsets ([9649d9f](https://github.com/folke/noice.nvim/commit/9649d9fd4d8fa8a8654e1e9c293718ae8d62e73b))

## [1.12.1](https://github.com/folke/noice.nvim/compare/v1.12.0...v1.12.1) (2023-04-17)


### Bug Fixes

* **router:** properly disable updater when disabling Noice. Fixes [#423](https://github.com/folke/noice.nvim/issues/423) ([3bed83b](https://github.com/folke/noice.nvim/commit/3bed83b4d2e4fce03a27071c39be0d9e04313332))

## [1.12.0](https://github.com/folke/noice.nvim/compare/v1.11.0...v1.12.0) (2023-04-16)


### Features

* added `Noice dismiss` to hide all visible messages. Fixes [#417](https://github.com/folke/noice.nvim/issues/417) ([a32bc89](https://github.com/folke/noice.nvim/commit/a32bc892aadb26668fd0161962ae4eccb1bf5854))

## [1.11.0](https://github.com/folke/noice.nvim/compare/v1.10.2...v1.11.0) (2023-04-16)


### Features

* **lsp:** added config.lsp.hover.silent. Fixes [#412](https://github.com/folke/noice.nvim/issues/412) ([e2a53cf](https://github.com/folke/noice.nvim/commit/e2a53cf946d88d87cd0123711afce5ddad047b7b))
* **signature:** added signature param docs. Fixes [#421](https://github.com/folke/noice.nvim/issues/421) ([e76ae13](https://github.com/folke/noice.nvim/commit/e76ae13dd272dc23d0154b93172d445aeabad8f1))


### Bug Fixes

* **confirm:** keep newlines in confirm message. Fixes [#422](https://github.com/folke/noice.nvim/issues/422) ([051111f](https://github.com/folke/noice.nvim/commit/051111f98d7128c833eaa32423426829981b2aa3))
* **markdown:** replace `&lt;code&gt;`. Fixes [#424](https://github.com/folke/noice.nvim/issues/424) ([38fb652](https://github.com/folke/noice.nvim/commit/38fb652d0a95780d20a551a6ec44b01226476c99))
* **markdown:** revert ([d767be9](https://github.com/folke/noice.nvim/commit/d767be960e8660b19595ccff2dad6abd7aae2d4a))

## [1.10.2](https://github.com/folke/noice.nvim/compare/v1.10.1...v1.10.2) (2023-03-26)


### Bug Fixes

* **icons:** removed all obsolete icons thanks to nerdfix ([cf6a194](https://github.com/folke/noice.nvim/commit/cf6a194f9280cda1fdcc36d271fccd4a24082df3))

## [1.10.1](https://github.com/folke/noice.nvim/compare/v1.10.0...v1.10.1) (2023-03-24)


### Bug Fixes

* **treesitter:** deprecated call. Fixes [#408](https://github.com/folke/noice.nvim/issues/408) ([1ded575](https://github.com/folke/noice.nvim/commit/1ded575928752861558a729fcbbd1e6e53c76652))

## [1.10.0](https://github.com/folke/noice.nvim/compare/v1.9.5...v1.10.0) (2023-03-23)


### Features

* **cmdline:** added cmdline support for `:lua=` and `:=` ([acfa513](https://github.com/folke/noice.nvim/commit/acfa5133da31a35ec24fca0757ad1c85edc4c585))

## [1.9.5](https://github.com/folke/noice.nvim/compare/v1.9.4...v1.9.5) (2023-03-19)


### Bug Fixes

* **views:** dont highlight CurSearch for some views. Fixes [#399](https://github.com/folke/noice.nvim/issues/399) ([0c493e5](https://github.com/folke/noice.nvim/commit/0c493e5d243c39adf3d6ce7683a16e610cc44e0a))

## [1.9.4](https://github.com/folke/noice.nvim/compare/v1.9.3...v1.9.4) (2023-03-15)


### Bug Fixes

* **markdown:** better check to see if a ts parser is available. Fixes [#397](https://github.com/folke/noice.nvim/issues/397) ([d60bee1](https://github.com/folke/noice.nvim/commit/d60bee1b85af1882768af80385bc2500d495feba))
* **markdown:** strip "\r" chars ([4d2801b](https://github.com/folke/noice.nvim/commit/4d2801babc4026229c58f0c77a20ff5b7b4c0d07))

## [1.9.3](https://github.com/folke/noice.nvim/compare/v1.9.2...v1.9.3) (2023-03-14)


### Bug Fixes

* **cmdline:** dont use normal commands so ModeChanged will trigger correctly. Fixes [#390](https://github.com/folke/noice.nvim/issues/390) ([fa7b6a1](https://github.com/folke/noice.nvim/commit/fa7b6a18c5cdc23961038bc56b93495efcd0f5c7))

## [1.9.2](https://github.com/folke/noice.nvim/compare/v1.9.1...v1.9.2) (2023-03-12)


### Bug Fixes

* **cmdline:** make sure cursor is always visible ([2f0a427](https://github.com/folke/noice.nvim/commit/2f0a42701b4aa65b55fff8f32878d9adc7e7ac77))
* **config:** allow overriding options set by presets ([5a1bf17](https://github.com/folke/noice.nvim/commit/5a1bf1707f592fefff4cb3da903b17369e088cc1))
* **config:** correctly set the presets ([e5cb84f](https://github.com/folke/noice.nvim/commit/e5cb84f1ed524f850fa92e3a256e830ed07fadee))

## [1.9.1](https://github.com/folke/noice.nvim/compare/v1.9.0...v1.9.1) (2023-03-03)


### Bug Fixes

* **health:** correctly check if lsp.message is enabled ([#381](https://github.com/folke/noice.nvim/issues/381)) ([1ff6b10](https://github.com/folke/noice.nvim/commit/1ff6b10471590331cc1585ad64f084f19cd4bcb7))

## [1.9.0](https://github.com/folke/noice.nvim/compare/v1.8.3...v1.9.0) (2023-03-03)


### Features

* **lsp:** fallback to buffer filetype for code blocks without lang. Fixes [#378](https://github.com/folke/noice.nvim/issues/378) ([cab2c80](https://github.com/folke/noice.nvim/commit/cab2c80497388735c9795f496a36e76bc5c7c4bf))


### Bug Fixes

* **treesitter:** use the new treesitter ft to lang API if availble. Fixes [#378](https://github.com/folke/noice.nvim/issues/378) ([36d141b](https://github.com/folke/noice.nvim/commit/36d141bd5852b10e32058e259982182b9e5e8060))

## [1.8.3](https://github.com/folke/noice.nvim/compare/v1.8.2...v1.8.3) (2023-03-02)


### Bug Fixes

* **notify:** take col offsets into account for nvim-notify renderers. Fixes [#375](https://github.com/folke/noice.nvim/issues/375) ([20596d9](https://github.com/folke/noice.nvim/commit/20596d96551605f7462f5722198b188e4047b605))

## [1.8.2](https://github.com/folke/noice.nvim/compare/v1.8.1...v1.8.2) (2023-02-07)


### Bug Fixes

* **signature:** when loading, attach to existing lsp clients. Fixes [#342](https://github.com/folke/noice.nvim/issues/342) ([f69f1a5](https://github.com/folke/noice.nvim/commit/f69f1a577615a5a6527f133df0aa40e596bd1707))

## [1.8.1](https://github.com/folke/noice.nvim/compare/v1.8.0...v1.8.1) (2023-02-06)


### Bug Fixes

* **ui:** cmdline is always blocking. Fixes [#347](https://github.com/folke/noice.nvim/issues/347) ([6702d97](https://github.com/folke/noice.nvim/commit/6702d97d3c37c3a363ffc7c890578109f82f9f20))

## [1.8.0](https://github.com/folke/noice.nvim/compare/v1.7.1...v1.8.0) (2023-01-24)


### Features

* added deactivate ([bf216e0](https://github.com/folke/noice.nvim/commit/bf216e017979f8be712b1ada62736a58e75b0fe3))


### Bug Fixes

* Allow mapping &lt;esc&gt; ([#329](https://github.com/folke/noice.nvim/issues/329)) ([b7e9054](https://github.com/folke/noice.nvim/commit/b7e9054b02b5958db8bb5ad7675e92bfb5a8e903))

## [1.7.1](https://github.com/folke/noice.nvim/compare/v1.7.0...v1.7.1) (2023-01-23)


### Bug Fixes

* **nui:** make sure nui recreates buffer and window when needed ([3e6dfd8](https://github.com/folke/noice.nvim/commit/3e6dfd8bb00d98399704a020ab7892234ce80fdb))
* **nui:** mount if buffer is no longer valid ([71d7b5c](https://github.com/folke/noice.nvim/commit/71d7b5cf8f24b9bdc425934c36cfda784fcd10f2))
* **nui:** set mounted=false if buffer is no longer valid ([3353a7a](https://github.com/folke/noice.nvim/commit/3353a7ab4bae6c22f61fd646c10e336b4582f0ea))


### Performance Improvements

* make noice a bit more robust when exiting to prevent possible delays on exit ([35e3664](https://github.com/folke/noice.nvim/commit/35e3664297096d8e24ca17f590bc793482f5182d))

## [1.7.0](https://github.com/folke/noice.nvim/compare/v1.6.2...v1.7.0) (2023-01-14)


### Features

* **ui:** added hybrid messages functionality, but not needed for now ([addc0a2](https://github.com/folke/noice.nvim/commit/addc0a2521ce666a1f546f9a04574a63a858c6a5))


### Bug Fixes

* **swap:** additionally check for updates when a swap file was found ([1165d3e](https://github.com/folke/noice.nvim/commit/1165d3e727bdd226eefffcc801d563bcb30e71c4))
* **ui:** work-around for segfaults in TUI. Fixes [#298](https://github.com/folke/noice.nvim/issues/298) ([176ec31](https://github.com/folke/noice.nvim/commit/176ec31026ec4baf64638fba1a180701257380f1))

## [1.6.2](https://github.com/folke/noice.nvim/compare/v1.6.1...v1.6.2) (2023-01-13)


### Bug Fixes

* **ui_attach:** dont update router during `ext_messages` and disable/enable Noice during confirm. [#298](https://github.com/folke/noice.nvim/issues/298) ([a4cbc0f](https://github.com/folke/noice.nvim/commit/a4cbc0f0cebdaa9529a749f4463aedc5a2cdcf1b))

## [1.6.1](https://github.com/folke/noice.nvim/compare/v1.6.0...v1.6.1) (2023-01-10)


### Bug Fixes

* show unstable message after loading noice ([2613a16](https://github.com/folke/noice.nvim/commit/2613a16b5009acbf2adabb34b029b1c4c57101e3))

## [1.6.0](https://github.com/folke/noice.nvim/compare/v1.5.2...v1.6.0) (2023-01-10)


### Features

* show warning when running with TUI rework ([cf2231b](https://github.com/folke/noice.nvim/commit/cf2231bfb691b3b58d2685f48da11596cec1cfa3))

## [1.5.2](https://github.com/folke/noice.nvim/compare/v1.5.1...v1.5.2) (2023-01-01)


### Bug Fixes

* **treesitter:** only disable injections for php and html ([0e1bf11](https://github.com/folke/noice.nvim/commit/0e1bf11d46054b8ab04eb62b53c5ac81b44f14df))

## [1.5.1](https://github.com/folke/noice.nvim/compare/v1.5.0...v1.5.1) (2022-12-31)


### Bug Fixes

* dont error in checkhealth if nvim-treesitter is not installed ([044767a](https://github.com/folke/noice.nvim/commit/044767a01d38208c32d97b0214cce66c41e8f7c8))
* **health:** dont use nvim-treesitter to check if a lang exists ([585d24e](https://github.com/folke/noice.nvim/commit/585d24ec6e3fb4288414f864cfe2de7d025e8216))
* **notify_send:** properly close file descriptors from spwaning notifysend ([f5132fa](https://github.com/folke/noice.nvim/commit/f5132fa6eb71e96d9f0cd7148b186b324b142d15))
* **nui:** dont trigger autocmds when doing zt ([d176765](https://github.com/folke/noice.nvim/commit/d176765ceabae9a12bf09a5c785d3dcb3859e1b6))
* **popupmenu:** replace any newlines by space. Fixes [#265](https://github.com/folke/noice.nvim/issues/265) ([5199089](https://github.com/folke/noice.nvim/commit/51990892e1dd5ee1a1444b1cf3ccf0aca377e0c4))
* **treesitter:** dont allow recursive injections. Fixes [#286](https://github.com/folke/noice.nvim/issues/286) ([a31b41a](https://github.com/folke/noice.nvim/commit/a31b41a739731988fc30a48a3099586a884bdf61))

## [1.5.0](https://github.com/folke/noice.nvim/compare/v1.4.2...v1.5.0) (2022-12-21)


### Features

* added `Filter.cond` to conditionally use a route ([29a2e05](https://github.com/folke/noice.nvim/commit/29a2e052d2653443716a8eece89300e9b36b5f2a))
* **format:** allow `config.format.level.icons` to be false. Fixes [#274](https://github.com/folke/noice.nvim/issues/274) ([aa68eb6](https://github.com/folke/noice.nvim/commit/aa68eb6f83c48df41bab8ae36623e5af3f224c66))


### Bug Fixes

* correctly apply padding based on four numbers ([c9c1fbd](https://github.com/folke/noice.nvim/commit/c9c1fbd605388badcfa62c0b7f58d184f19e1484))
* **nui:** removed work-around for padding and border style shadow ([4f34d33](https://github.com/folke/noice.nvim/commit/4f34d33fc3dc0d6f4da9b4b8c63b9714fd4eea79))

## [1.4.2](https://github.com/folke/noice.nvim/compare/v1.4.1...v1.4.2) (2022-12-16)


### Bug Fixes

* **debug:** calculate stacktrace outisde of vim schedule to make it useful ([a5de1ca](https://github.com/folke/noice.nvim/commit/a5de1ca0eaecd21fd33a0a191d1a0b9dd97cb54a))
* **debug:** only concat debug info that is a string ([78ec5c6](https://github.com/folke/noice.nvim/commit/78ec5c6eefb9b61056a8545ded33b99f7a9a9f72))
* **nui:** remove border text when style is `nil`, `"none"`, or `"shadow"` ([d85a4d0](https://github.com/folke/noice.nvim/commit/d85a4d01774b5649dbcda8526a26f201dff5ade4))
* **nui:** remove padding when border is `shadow` ([1515007](https://github.com/folke/noice.nvim/commit/151500759722c12fb6a3931c5243d68f01af007a))

## [1.4.1](https://github.com/folke/noice.nvim/compare/v1.4.0...v1.4.1) (2022-12-03)


### Bug Fixes

* scrollbar destructs itself, so make a copy to see if there are any remnants left ([8d80a69](https://github.com/folke/noice.nvim/commit/8d80a692d5a045a3ec995536782f2b4c2b8d901b))
* stop processing messages when Neovim is exiting. Fixes [#237](https://github.com/folke/noice.nvim/issues/237) ([8c8acf7](https://github.com/folke/noice.nvim/commit/8c8acf74c09374e48a8fa1835560c3913d57243f))

## [1.4.0](https://github.com/folke/noice.nvim/compare/v1.3.1...v1.4.0) (2022-12-03)


### Features

* added support for &lt;pre&gt;{lang} code blocks used in the Neovim codebase ([de48a45](https://github.com/folke/noice.nvim/commit/de48a4528aad5c7b50cf4b4ec1b419762a95934d))


### Bug Fixes

* check if loader returned a function before loading ([66946c7](https://github.com/folke/noice.nvim/commit/66946c72f0a36f37e480b5eae97aac3cdcd5961d))
* reset preloader before trying to load the module ([08655e9](https://github.com/folke/noice.nvim/commit/08655e9f1bed638f9871d76b05928da74d1eeb68))

## [1.3.1](https://github.com/folke/noice.nvim/compare/v1.3.0...v1.3.1) (2022-12-01)


### Bug Fixes

* dont error if cmp not loaded when overriding ([4bae487](https://github.com/folke/noice.nvim/commit/4bae48798424d300e204cce2eb73b087854472d5))
* wait to override cmp till it loaded ([712180f](https://github.com/folke/noice.nvim/commit/712180f94684b7ce56957df60d037c81784e69c3))
