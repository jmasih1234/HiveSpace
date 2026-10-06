# HiveSpace Visual Specification

Stage A audit and implementation plan for the premium UI/UX transformation.

This document uses the supplied HiveSpace reference board as art direction. It does not authorize fake data, backend changes, or unsupported product behavior.

## Reference Breakdown

### Overall Direction

The reference reads as a premium consumer lifestyle product, not a utility dashboard. It combines warm residential photography, editorial typography, compact data surfaces, human avatars, and precise task/finance/messaging modules.

The design language is:

- Home-first and people-first.
- Warm, architectural, cinematic, and residential.
- Dense enough to be useful, but composed with editorial hierarchy.
- Screen-specific in atmosphere: Home and Trips are photographic, Tasks and House are warm/light, Expenses/Messages/Health are dark.

### Screen Layouts

Home:

- Top chrome sits over the hero image: small HiveSpace mark/name, notification action, circular profile avatar.
- The hero is a large interior photograph with gradient overlay and large serif greeting.
- Summary modules float on the lower part of the photo, using compact dark translucent surfaces.
- A darker household snapshot card follows the hero with health score, small chart, and a navigation chevron.
- Human activity appears as a compact message/activity card with avatar and timestamp.

Tasks:

- Light warm paper background.
- Editorial title with compact week selector and plus action.
- Segmented filters immediately below title.
- Task groups are efficient, rounded-but-not-bubbly list sections with completion circles, assignee avatars, and due labels.

Expenses:

- Dark charcoal environment.
- Serif title, compact add button, pill filters.
- Main balance card uses precise money text and a small chart.
- Activity rows are dense, with category icon, participants, amount, payer/status, and date.

Messages:

- Near-black background with compact search.
- Conversation list rows have avatars, names, previews, timestamps, and unread badges.
- Hierarchy is clear and intimate; no oversized chat cards.

Trips:

- Warm light environment with large destination imagery.
- Trip cards use photography, title/date overlays, participants, and progress/action lists.

Calendar:

- Dark organized timeline with horizontal date selector and vertical schedule.
- This remains a later-stage design target because Calendar is not currently a primary tab.

House:

- Warm light atmosphere.
- Household title, member avatars, invite action, and organized settings rows.
- It should feel personal before administrative.

Hive Health:

- Dark analytical surface.
- Central circular score visualization, metric rows, calm teal/sage accents.

Calls:

- Dark intimate grid of participant tiles.
- Existing app should keep this as a visual call room until real media transport/signaling exists.

### Composition Rules From Reference

- Photography must be a layout element, not a decorative background afterthought.
- Dark overlays should be directional gradients, strongest where text sits.
- Cards are compact and purposeful; avoid stacking large generic cards.
- Tab bar is compact with small icons and labels; selected state is clear but restrained.
- Accent color appears sparingly: status, selected tabs, progress, important actions.
- Avatars are small, frequent, and humanize list rows.
- Typography uses serif only for emotional/section identity, never for all labels.

## Current UI Audit

### Current Strengths

- Existing app already has a coherent model/store layer and feature modules.
- `HiveColor`, `HiveFont`, `HiveSpacing`, `HiveRadius`, `HiveScreen`, `HiveCard`, `HivePageHeader`, `HiveTaskRow`, and `HiveHealthIndicator` provide a useful foundation.
- Navigation is functional with tabs for Home, Tasks, Expenses, Calls, House, and Inbox.
- Home already exposes real data needed for the redesign: current user, colony, tasks, expenses, messages, health score, activity, chores, trips, and calls.
- Store methods preserve interactions: task completion, nudges, expense settlement, messaging, calls, colony switching.

### Current Gaps

Home:

- Current layout is a vertical utility feed rather than an immersive photo-led home.
- No photography or image treatment exists.
- Greeting is separate from household context instead of anchored in a hero composition.
- Quick household summary is text-only and not layered into the main composition.
- Activity is a plain list, not a human editorial moment.
- Health appears as a generic card rather than a dark premium snapshot.

Design system:

- Current color tokens are warm but not expressive enough for screen-specific atmospheres.
- No semantic tokens for photo overlays, dark panels, warm paper, bronze, teal, or espresso surfaces.
- `HiveCard` is useful but too generic to carry every redesigned surface.
- No reusable photo hero, image card, avatar stack, metric sparkline, or premium status chip.

Navigation:

- Current `TabView` uses standard system tab bar styling. This is functional and accessible, but less premium than the reference.
- Any custom tab treatment must preserve working tab semantics and avoid an oversized floating pill.

Screens beyond Home:

- Tasks uses oversized cards for each task; reference prefers denser grouped rows.
- Expenses has correct logic but light/default card structure; reference wants dark, data-rich composition.
- Inbox exists as a simplified channel list in `MainTabView`; `MessagingView` is a fuller chat experience but still uses generic rounded panels.
- Trips has functional itinerary/packing/polls, but hero is symbolic rather than photographic.
- House is currently closer to settings than a personal household page.
- Health is currently a component, not a dedicated analytical screen.

## Gap Analysis

| Area | Reference Intent | Current State | Required Change |
| --- | --- | --- | --- |
| Home composition | Photo hero plus layered summary | Stacked content sections | Rebuild Home structure around photo hero |
| Photography | Core identity element | No assets/treatments | Add image slots and reusable photo treatment |
| Typography | Editorial serif for emotional titles | Serif exists but used simply | Define scale and screen-specific usage |
| Cards | Compact, purposeful surfaces | Generic card repeated widely | Add specialized surfaces and reduce card overload |
| Activity | Human, avatar-rich editorial rows | Icon rows | Add activity rows with avatars/actor emphasis |
| Health | Dark premium snapshot | Light generic card | Add dark health snapshot variant |
| Tasks | Dense grouped rows | Large cards | Later-stage list restructuring |
| Expenses | Dark data-rich | Light card stack | Later-stage dark screen treatment |
| Messaging | Dark intimate list | Simplified Inbox, generic chat | Later-stage compact conversation list |
| Assets | Real residential/travel photos | None | Add named asset slots before implementation |

## Visual System Tokens

Tokens should be added semantically to the existing `HiveColor`, not as hardcoded view colors.

### Core Palette

| Token | Hex | Usage |
| --- | --- | --- |
| `warmIvory` | `#F7F0E6` | Light app/home/house base |
| `softCream` | `#EDE1D1` | Secondary warm surfaces |
| `warmPaper` | `#FFF9F1` | Tasks/forms/content panels |
| `sand` | `#D8BE9F` | Borders, muted fills |
| `bronze` | `#B58B5C` | Brand mark, premium accent |
| `deepEspresso` | `#211C18` | Warm dark text/surfaces |
| `midnightCharcoal` | `#0B1213` | Dark screens |
| `elevatedCharcoal` | `#152022` | Dark cards/panels |
| `softTeal` | `#6BB8A5` | Positive dark accent/charts |
| `mutedSage` | `#9CB9A2` | Health/settled/completed |
| `coral` | `#E18D73` | Due/destructive/high attention |
| `primaryLightText` | `#F8F4EE` | Text on dark/photo |
| `secondaryLightText` | `#A7AEAC` | Secondary text on dark/photo |

### Semantic Atmosphere Tokens

- `homeBackground`: adaptive warm ivory/dark charcoal.
- `homeHeroOverlay`: black/espresso gradient with 0.12 to 0.72 opacity.
- `photoTextPrimary`: primary light text.
- `photoTextSecondary`: secondary light text.
- `warmScreenBackground`: warm ivory in light mode, midnight charcoal in dark mode.
- `paperScreenBackground`: warm paper in light mode, midnight charcoal in dark mode.
- `darkScreenBackground`: midnight charcoal in both appearances unless accessibility contrast requires lift.
- `darkElevatedSurface`: elevated charcoal.
- `darkInsetSurface`: charcoal mixed with deep espresso.
- `premiumAccent`: bronze.
- `livingAccent`: soft teal.
- `successAccent`: muted sage.
- `attentionAccent`: coral.

### Typography Scale

Use Dynamic Type-friendly custom helpers where possible rather than fixed visual-only sizes.

| Role | Font Direction | Approx Size | Usage |
| --- | --- | --- | --- |
| Editorial hero | Serif semibold | 34-40 | Home greeting, major emotional title |
| Screen title | Serif semibold | 28-32 | Home, Expenses, House, Trips |
| Section title | Sans semibold | 17-20 | Functional groups |
| Body title | Sans semibold | 15-17 | Task/expense/conversation titles |
| Body | Sans regular | 14-16 | Descriptions and previews |
| Metadata | Sans medium/regular | 11-13 | Timestamps, labels, status |
| Amount/metric | Sans or mono semibold | 24-36 | Balance, health, numeric stats |

Rules:

- Use serif for emotional identity, not dense rows.
- Avoid all-caps body copy; reserve tracked uppercase for tiny labels.
- Support long names by line wrapping or minimum scale only where necessary.
- Prefer `.font(...)` wrappers that can be upgraded to relative text styles.

### Spacing and Radius

Existing spacing can remain, with additions:

- Screen horizontal padding: 20-24.
- Hero outer margin: 12-16 from screen edge.
- Hero height: roughly 58-68% of available first viewport on Home, with responsive minimum around 420 on standard phones.
- Compact row vertical padding: 10-14.
- Card radius: 14 for cards, 18-22 for photo panels/hero, 8-10 for controls.
- Avoid large pill buttons except segmented filters/search fields.

### Shadows and Borders

- Light mode cards: very soft shadow, low opacity; thin warm border.
- Dark mode cards: mostly border/tonal separation, not heavy shadow.
- Photo overlays: no hard borders unless card is inset.
- Tab bar: system material or compact elevated surface; no giant floating capsule.

## Component Mapping

### Extend Existing Components

`HiveColor`

- Add screen atmosphere colors and premium accents.

`HiveFont`

- Add named semantic roles such as `heroGreeting`, `screenSerifTitle`, `metricLarge`, `rowTitle`, `metadata`.

`HiveScreen`

- Allow optional background style, for example warm, paper, dark, or transparent/photo.

`HiveCard`

- Keep for simple surfaces, but add variants or dedicated components instead of overloading it.

`HivePageHeader`

- Keep for non-Home screens, but Home should have a custom hero header.

`HiveTaskRow`

- Evolve for dense task lists in Stage D.

`HiveHealthIndicator`

- Reuse calculation inputs, but create a dark compact Home snapshot variant and later a dedicated Health visualization.

### New Components Proposed

`HivePhotoHero`

- Displays a named asset or placeholder/fallback.
- Supports aspect ratio/height, focal positioning, gradient overlay, clipped corners, loading/failure states, and accessibility label.
- Should not distort images.

`HiveHeroChrome`

- Logo/name, notification button, profile avatar over photo.
- Used on Home only initially.

`HiveStatusChip`

- Compact icon/title/value chip for Tasks due, Expenses pending, upcoming plan.
- Supports dark/photo and light variants.

`HiveActivityRow`

- Avatar/initial, natural-language event text, timestamp, optional trailing icon.

`HiveAvatar`

- Initial/avatar fallback with consistent sizes and accessibility.

`HiveMemberStack`

- Overlapping avatars for household/trips/expenses.

`HiveMetricSparkline`

- Small deterministic visualization from real values only.
- For Home health snapshot and Expenses later.

`HiveImageCard`

- Photo-backed card for Trips/House later.

## Asset Requirements

No arbitrary hotlinked copyrighted images should be used.

Named asset slots:

| Asset Name | Required For | Description |
| --- | --- | --- |
| `home_hero_interior` | Stage C Home | Warm residential interior, readable dark overlay area on left/bottom |
| `home_activity_dinner` | Optional Home activity | Human/residential vignette; can be deferred |
| `trip_big_sur` | Trips preview/stage | Destination landscape/coast |
| `trip_taipei` | Trips stage | City/travel photo |
| `house_common_area` | House stage | Warm household/common area |

If production assets are unavailable in Stage C:

- Use an asset placeholder component with warm tonal fallback.
- Clearly mark missing assets in code comments and this doc.
- Do not ship random internet images without license clarity.

Image treatment:

- Use `.scaledToFill()` with fixed aspect/height container and clipping.
- Use top/bottom or leading/bottom gradient overlays.
- Always provide accessibility labels.
- Use `Image` asset names initially; add async/caching only if remote images become product data.

## Screen Composition Plans

### Stage C: Home

Data inputs:

- `store.currentUser.displayName`
- `store.colony.name`, `store.colony.memberCount`, `store.colony.members`
- `store.openTasks`, due dates, assignees
- `store.unsettledExpenses`, `store.outstandingBalanceTotal`
- `store.activeTrip` or `store.activeAvailabilityPoll` for upcoming plan
- `store.healthScore`
- `store.activityEvents`
- `store.messageChannels`/latest messages where appropriate
- `selectedTab` binding for navigation shortcuts

Proposed layout:

1. Full-width `HivePhotoHero` near top, edge-to-edge within safe margins.
2. Overlay top chrome: HiveSpace logo/name left; notification and profile avatar right.
3. Overlay greeting: `"Good morning,\nAvery."` with first name extraction from display name.
4. Subtitle: contextual line from current data, e.g. tasks due or calm state.
5. Bottom overlay chips:
   - Tasks due count.
   - Expenses pending count or total.
   - Upcoming plan from active trip/availability/call if present.
6. Dark `HouseholdSnapshotCard` below or partially overlapping hero:
   - Hive Health score.
   - Short health summary.
   - Real mini visualization derived from health component rates.
   - Chevron/action to House or Health destination if available.
7. Human activity section:
   - 2-3 recent real events with avatars/initials and relative timestamps.
   - Latest meaningful message card if available.
8. Small task preview only if it adds value; avoid duplicating entire Tasks screen.

Interactions preserved:

- Notification button changes `selectedTab = .inbox`.
- Task chip changes `selectedTab = .tasks`.
- Expense chip changes `selectedTab = .expenses`.
- Plan chip links to relevant existing route only if route is available; otherwise no decorative button.
- Activity rows remain informational unless existing destination exists.

What to remove from current Home:

- Standalone house identity card, unless reworked into hero/snapshot.
- Large generic health card.
- Text-only Today section.
- Full chore wheel section on Home unless reduced to one relevant activity.

### Later Screen Directions

Tasks:

- Warm paper background.
- Header: title, timeframe selector, add button.
- Segmented filters: All/My Tasks/Chores/Done or current supported statuses.
- Group by Today/This Week/Chores using dense rows.

Expenses:

- Dark screen style.
- Balance summary at top with real outstanding totals.
- Filter chips derived from supported data.
- Rows should use real amount, payer, participants, settlement status.

Messages/Inbox:

- Dark conversation list with search.
- Use `messageChannels`, `directThreads`, unread counts, latest previews.
- Avoid implying call status unless call state exists.

Trips:

- Photo cards for `store.activeTrip`.
- Keep itinerary/packing/polls/split features intact.

House:

- Warm household profile with member avatars and invite action.
- Settings rows move below people and home identity.

Hive Health:

- Dedicated screen only if navigation/product route is added intentionally.
- Metrics must use existing `HiveHealthScore` fields.

Calls:

- Keep visual call-room treatment separate from real media claims.
- Copy should avoid "FaceTime" or "live video" unless transport exists.

## Exact Files To Modify In Stage B/C

Stage B design system:

- `Views/AppTheme.swift`
- `Views/HiveComponents.swift`
- Add image assets to the app asset catalog or Swift Package resources if available.

Stage C Home:

- `Views/HomeView.swift`
- Potentially `Views/MainTabView.swift` only for tab bar visual polish, preserving tab semantics.
- No model/repository/service changes expected.

Documentation:

- Update this file with approved decisions and asset status.

Do not modify:

- Repositories.
- Supabase services.
- Auth flow.
- Persistence format, unless adding optional non-breaking asset metadata later.
- Data models for visual convenience.

## Regression Risks

Functional risks:

- Custom tab bar could break native tab behavior, badges, VoiceOver, and safe areas.
- Hero overlay buttons could become unreadable on photo variants.
- Task/expense shortcuts could become decorative if not wired through `selectedTab`.
- Large photo assets could increase app size if unmanaged.

Accessibility risks:

- Text over imagery may fail contrast without robust overlays.
- Serif hero text must scale and wrap with Dynamic Type.
- Dense rows must retain tap targets of at least 44 points for controls.
- Reduced Motion should disable image reveal/parallax effects.

Data risks:

- Reference numbers must not be copied.
- Charts must be derived from real app data or omitted.
- Trip/photo modules must not display fake destinations in live sessions.

Implementation risks:

- Current views use many computed properties; Stage B/C should use focused subviews where new sections become substantial.
- Existing `HiveTheme` compatibility aliases should remain during migration.
- `HomeView` should not become an enormous single body; new components should narrow inputs.

## Visual Verification Plan

For Stage C Home implementation:

1. Build with `BuildProject`.
2. Run iPhone simulator using the available device interaction tooling.
3. Capture screenshots for at least:
   - Small iPhone size.
   - Standard/Pro size.
   - Light appearance.
   - Dark appearance if available.
4. Compare screenshot to reference Home panel.
5. Identify five largest differences:
   - Hero photo prominence.
   - Greeting hierarchy.
   - Overlay chip density and placement.
   - Household snapshot surface.
   - Activity/human warmth.
6. Iterate until composition is recognizably aligned.

If simulator capture is unavailable, report the limitation explicitly and do not claim visual verification.

## Stage B/C Approval Proposal

Recommended next approval scope:

1. Add Stage B tokens and reusable components:
   - `HivePhotoHero`
   - `HiveStatusChip`
   - `HiveActivityRow`
   - `HiveAvatar`
   - `HiveMetricSparkline`
2. Add or wire placeholder named asset slot `home_hero_interior`.
3. Rebuild `HomeView` only.
4. Build and visually verify Home.
5. Stop for approval before Tasks.

Open decisions:

- Should the first Home pass use a bundled placeholder photo asset supplied by the user, or should it use a generated/licensed placeholder asset?
- Should tab bar polish happen in Stage C, or wait until after Home composition is approved?
- Should Home include one latest message preview, or only activity events in the first pass?
