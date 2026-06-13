# Gist · 简研

**English** · [简体中文](#)

> Your ideas. Your papers. Your research rhythm.
>
> An iOS research companion that captures everything — papers, articles, competitions, voice notes, flashes of insight — and brings them together in one dark, quiet space.

[App Store](#) · [What's new](#whats-new) · [Features](#highlights) · [Install](#quickstart) · [Contributing](#contributing) · [License](#license)

**Open-source companion for:** researchers · graduate students · competition teams · knowledge workers who need more than a bookmark manager

<p align="center">
  <img src="https://raw.githubusercontent.com/OpenCoworkAI/open-codesign/main/website/public/screenshots/product-hero.png" alt="Gist — research companion iOS app" width="400" />
</p>

<p align="center">
  <a href="#"><img alt="Platform" src="https://img.shields.io/badge/platform-iOS%2017%2B-blue" /></a>
  <a href="#"><img alt="Swift" src="https://img.shields.io/badge/swift-6.0-orange" /></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-blue" /></a>
  <a href="#"><img alt="Status" src="https://img.shields.io/badge/stage-1%20%E2%80%94%20foundations-6c5ce7" /></a>
</p>

<p align="center">
  <sub><code>ios</code> · <code>swiftui</code> · <code>swiftdata</code> · <code>research-tool</code> · <code>paper-manager</code> · <code>knowledge-management</code> · <code>ai-research</code> · <code>local-first</code> · <code>dark-mode</code> · <code>competition-tracker</code></sub>
</p>

---

## What's new

- **Stage 1 — Foundations** *(current)* — Five data types, project aggregation, three-tab navigation, competition deadline tracking, insight revisiting engine, full dark theme system. See [ROADMAP.md](./ROADMAP.md).
- **Stage 0 — Scaffold** *(2026-06)* — SwiftData schema with 5 models, `GistTheme` design system, `GistNavigationRouter`, `GistSheetManager`, `GistToastCenter`, `GistDataChangeCenter`, launch configuration system with acceptance seed.

---

## What it is

A single iOS app that replaces the scattered workflow of managing research materials.

**Gist (简研) is a local-first research companion** — built for people who collect papers, articles, competition notices, voice memos, and spontaneous ideas, then need to bring them together into projects, track reading progress, and eventually have AI help them synthesize. MIT-licensed, SwiftUI native, dark-only by design.

---

## Why people use it

| Pain point | Gist's answer |
|---|---|
| Papers in one app, ideas in another, deadlines on a sticky note | Five material types in one library |
| "Where did I read that?" | Full-text storage + annotation + search (search Stage 2) |
| Competition deadlines sneak up | Deadline tracking with countdown cards on home |
| Ideas get lost | Weighted random "灵感漫游" resurfaces old insights |
| Reading pile grows but nothing gets read | Unread count front-and-center on home |
| AI tools feel bolted-on | AI interpretation pipeline designed from Stage 0 (real AI Stage 3) |

---

## Highlights

<table>
  <tr>
    <td width="50%">
      <p><b>🏠 Home workbench.</b><br/>Greeting + date, upcoming competition deadlines, unread count, recent reads, inspiration revisit, pending AI interpretation, active projects — all on one scroll.</p>
    </td>
    <td width="50%">
      <p><b>📚 Library directory.</b><br/>Status buckets (unread / all / today / starred / interpreted / annotated), project cards with stats, tag capsules. Every dimension navigable.</p>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <p><b>🔍 Explore with context.</b><br/>When your library has material, Explore suggests similar papers and competitions based on what you've already collected. Empty? It tells you so instead of showing noise.</p>
    </td>
    <td width="50%">
      <p><b>🧠 Five data types.</b><br/>Paper (DOI / arXiv / authors / venue), article (URL + source), competition (deadline / stage / checklist), voice (transcript + duration), insight (free-form). Each with its own form and detail view.</p>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <p><b>📁 Project aggregation.</b><br/>Group materials into projects. Each project gets: research background + questions, segmented material browser, competition node summary, AI project summary placeholder, todo list with check-off.</p>
    </td>
    <td width="50%">
      <p><b>🎨 Design system from day one.</b><br/><code>GistTheme</code> — colors, fonts, spacing, radius, icons, card modifier. Every view consumes it via <code>@Environment</code>. Dark-only palette: cool blue accent on deep gray background.</p>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <p><b>✨ Smart inspiration replay.</b><br/>The home page "灵感漫游" card uses a weighted random algorithm — newer and starred insights surface more often, but old ones still get their moment.</p>
    </td>
    <td width="50%">
      <p><b>🔧 Acceptance-testable.</b><br/>Launch configuration system lets you seed data, set initial routes, preload tab stacks, auto-open items. Built for demo and QA, not just development.</p>
    </td>
  </tr>
</table>

---

## Architecture

```
GistApp/
├── App/                    # @main entry, root view, launch support
├── Models/                 # ResearchItem, Project, Tag, Annotation, CaptureInboxItem
├── Persistence/            # SwiftData ModelContainer
├── Repositories/           # ResearchItemRepository, ProjectRepository, TagRepository
├── Navigation/             # GistNavigationRouter, GistSheetManager, enums
├── DesignSystem/           # GistTheme (colors, fonts, spacing, radius, icons, card)
├── Shared/
│   ├── Components/         # ResearchItemRow
│   └── Toast/              # GistToastCenter, GistToastOverlayView
└── Features/
    ├── Home/               # HomeWorkbenchView
    ├── Library/            # LibraryDirectoryView, ResearchItemListView
    ├── Explore/            # ExploreRootView
    ├── Detail/             # ResearchItemDetailView
    ├── Projects/           # ProjectDetailView, EditProjectSheet, ProjectAddItemSheet
    └── NewItem/            # NewItemSheet (5-type form)
```

**Stack:** SwiftUI · SwiftData · Observation framework · iOS 17+

**Key patterns:**
- `@Environment` for theme, router, sheet manager, toast center, data change center, and all three repositories
- `GistDataChangeCenter.revision` as a simple reactive invalidation token — views re-fetch on `.task(id: dataChangeCenter.revision)`
- SwiftData `@Transient` wrappers for enum-backed `RawRepresentable` stored properties
- Navigation via typed `GistNavigationDestination` enum on `NavigationPath`
- Sheets via `GistSheetType` enum + `GistSheetManager` (no scattered `.sheet` modifiers)
- Launch configuration system (`GistLaunchConfiguration`) supporting seed data, initial routes, preloaded tab stacks, and acceptance overlays

---

## Quickstart

**Requires:** Xcode 16+, iOS 17+ device or simulator

### 1. Clone

```bash
git clone https://github.com/your-org/Gist.git
cd Gist/GistApp
```

### 2. Open

```bash
open GistApp.xcodeproj
```

### 3. Run

Select an iOS 17+ simulator or device, then **⌘R**.

### 4. Acceptance seed (optional)

Edit `GistLaunchConfiguration` to enable `preloadTabStacks`, set `initialRoute`, or seed demo data for a full walkthrough.

---

## Project structure

```
gist4apple/
├── GistApp/                # Main iOS app (this repo)
├── Android-mobile-terminal/ # Android terminal companion
├── IceCubesApp/            # Upstream Mastodon client (for reference)
├── 迁移.md                 # Migration notes
└── 迁移plan/               # Migration plan files
```

---

## Roadmap

| Stage | Focus | Status |
|-------|-------|--------|
| 0 — Scaffold | SwiftData schema, design system, navigation infrastructure | ✅ Done |
| 1 — Foundations | Five data types, project aggregation, home/library/explore, detail views | 🚧 In progress |
| 2 — Search & capture | Global search, share extension capture, clipboard intake | ⬜ Planned |
| 3 — AI integration | Real AI interpretation pipeline, project-level synthesis, structured reading cards | ⬜ Planned |
| 4 — Collaboration | Shared projects, export, multi-device sync | ⬜ Planned |

---

## Contributing

Contributions welcome. The project follows a stage-gated development model — check the roadmap before starting on a feature.

1. Fork the repo
2. Create a feature branch
3. Match the existing patterns: `@Environment` injection, `GistTheme` consumption, `GistDataChangeCenter` invalidation
4. Open a PR with a clear description

---

## License

MIT — see [LICENSE](./LICENSE) for details.

---

<p align="center">
  <sub>Built with SwiftUI. Dark by default. Research-first.</sub>
</p>
