# InstaClone - Complete Architecture Documentation

## 📋 Table of Contents
1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Component Breakdown](#component-breakdown)
4. [Data Flow Diagrams](#data-flow-diagrams)
5. [API Endpoints](#api-endpoints)
6. [Navigation Flow](#navigation-flow)
7. [Threading Model](#threading-model)
8. [Core Data Schema](#core-data-schema)
9. [Upstream & Downstream Connections](#upstream--downstream-connections)

---

## Overview

**InstaClone** is an Instagram-like iOS application built with SwiftUI that features:
- User authentication (local validation)
- Feed view with posts (images)
- Reels view with vertical video scrolling
- Like/unlike functionality with optimistic UI updates
- Offline caching using Core Data
- Toast notifications for user feedback

**Tech Stack:**
- SwiftUI (UI Framework)
- Combine (Reactive Programming)
- Core Data (Persistence)
- AVKit (Video Playback)
- URLSession (Networking)

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        InstaCloneApp                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  PersistenceController (Singleton)                       │  │
│  │  - NSPersistentContainer                                  │  │
│  │  - viewContext (Main Queue)                              │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ Environment Injection
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                         LoginView                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  LoginViewModel (@StateObject)                          │  │
│  │  - Email/Password validation                            │  │
│  │  - UserDefaults persistence                            │  │
│  │  - Navigation trigger                                  │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ Navigation (on login)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                          FeedView                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  FeedViewModel (@StateObject)                            │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  CoreDataManager.shared                            │  │  │
│  │  │  - savePosts()                                     │  │  │
│  │  │  - fetchPosts()                                    │  │  │
│  │  │  - updatePost()                                    │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  │                                                          │  │
│  │  Network Layer:                                         │  │
│  │  - GET /user/feed                                       │  │
│  │  - POST /user/like                                      │  │
│  │  - DELETE /user/dislike                                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  PostView Components                                      │  │
│  │  - AsyncImage (user & post images)                       │  │
│  │  - Like button with optimistic updates                   │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                            │
                            │ Navigation (bottom tab)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                          ReelsView                               │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  ReelsViewModel (@StateObject)                           │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  VideoPlayerManager (@StateObject)                │  │  │
│  │  │  - AVPlayer lifecycle                              │  │  │
│  │  │  - Mute/unmute control                             │  │  │
│  │  │  - Auto-loop playback                              │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  │                                                          │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  CoreDataManager.shared                            │  │  │
│  │  │  - saveReels()                                     │  │  │
│  │  │  - fetchReels()                                    │  │  │
│  │  │  - updateReel()                                    │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  │                                                          │  │
│  │  Network Layer:                                         │  │
│  │  - GET /user/reels                                      │  │
│  │  - POST /user/like                                      │  │
│  │  - DELETE /user/dislike                                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  ReelPlayerView Components                                │  │
│  │  - VideoPlayer (AVKit)                                   │  │
│  │  - Vertical paging ScrollView                             │  │
│  │  - Like/comment/share buttons                             │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Breakdown

### 1. **InstaCloneApp** (Entry Point)
**File:** `InstaCloneApp.swift`

**Responsibilities:**
- App initialization
- URL cache configuration (50MB memory, 500MB disk)
- Core Data context injection into SwiftUI environment
- Root view setup (LoginView)

**Key Properties:**
```swift
let persistenceController = PersistenceController.shared
```

---

### 2. **PersistenceController** (Core Data Stack)
**File:** `Persistence.swift`

**Responsibilities:**
- Core Data stack initialization
- Persistent store configuration
- View context setup (main queue)

**Key Features:**
- Singleton pattern
- In-memory option for previews
- Automatic merge from parent context

**Configuration:**
```swift
container.viewContext.automaticallyMergesChangesFromParent = true
```

---

### 3. **CoreDataManager** (Data Persistence Layer)
**File:** `CoreDataManager.swift`

**Architecture Pattern:** Singleton

**Responsibilities:**
- CRUD operations for Posts
- CRUD operations for Reels
- Batch delete operations
- Thread-safe context management

**Key Methods:**

#### Posts Operations:
- `savePosts(_ posts: [Post])` - Saves posts (clears cache first)
- `fetchPosts() -> [Post]` - Retrieves all cached posts
- `updatePost(_ post: Post)` - Updates single post (for likes)
- `clearAllPosts()` - Removes all cached posts

#### Reels Operations:
- `saveReels(_ reels: [Reel])` - Saves reels (clears cache first)
- `fetchReels() -> [Reel]` - Retrieves all cached reels
- `updateReel(_ reel: Reel)` - Updates single reel (for likes)
- `clearAllReels()` - Removes all cached reels

**Thread Safety:**
- ✅ `savePosts()` / `saveReels()` - Uses `context.perform` (thread-safe)
- ⚠️ `fetchPosts()` / `fetchReels()` - Direct context access (NOT thread-safe)
- ⚠️ `updatePost()` / `updateReel()` - Direct context access (NOT thread-safe)

---

### 4. **LoginViewModel** (Authentication)
**File:** `LoginViewModel.swift`

**Architecture Pattern:** MVVM with ObservableObject

**Responsibilities:**
- Email/password validation
- Login state management
- UserDefaults persistence
- Navigation state

**State Properties:**
```swift
@Published var email: String
@Published var password: String
@Published var isLoggedIn: Bool
@Published var errorMessage: String?
```

**Key Methods:**
- `login()` - Validates credentials (hardcoded: `user@example.com` / `password123`)
- `logout()` - Clears session and UserDefaults
- `checkLoginState()` - Restores login state on app launch

**Persistence:**
- Stores `isLoggedIn` in UserDefaults
- Stores `userEmail` in UserDefaults

---

### 5. **FeedViewModel** (Feed Management)
**File:** `FeedViewModel.swift`

**Architecture Pattern:** MVVM with ObservableObject

**Responsibilities:**
- Fetching feed posts from API
- Managing post likes with optimistic updates
- Offline fallback to cached data
- Toast message management

**State Properties:**
```swift
@Published var isLoading: Bool
@Published var posts: [Post]
@Published var errorMessage: String?
@Published var showToast: Bool
@Published var toastMessage: String?
```

**Key Methods:**

#### `fetchFeed() async`
1. Sets loading state
2. Fetches from API: `GET /user/feed`
3. Saves to Core Data cache
4. Updates UI with fresh data
5. On error: Falls back to cached data or shows error

#### `toggleLike(for post: Post) async`
**Optimistic Update Pattern:**
1. Save old state (for rollback)
2. Optimistically update UI immediately
3. Update Core Data cache
4. Make API call (POST/DELETE /user/like)
5. On failure: Rollback UI and Core Data

**Network Methods:**
- `likePost(postId:)` - POST request to like endpoint
- `dislikePost(postId:)` - DELETE request to dislike endpoint

---

### 6. **ReelsViewModel** (Reels Management)
**File:** `ReelsViewModel.swift`

**Architecture Pattern:** MVVM with ObservableObject

**Responsibilities:**
- Fetching reels from API
- Managing reel likes with optimistic updates
- Offline fallback to cached data
- Toast message management

**State Properties:**
```swift
@Published var reels: [Reel]
@Published var isLoading: Bool
@Published var errorMessage: String?
@Published var showToast: Bool
@Published var toastMessage: String?
```

**Key Methods:**

#### `fetchReels() async`
1. Sets loading state
2. Fetches from API: `GET /user/reels`
3. Saves to Core Data cache
4. Updates UI with fresh data
5. On error: Falls back to cached data or shows error

#### `toggleLike(for reel: Reel) async`
Same optimistic update pattern as FeedViewModel

**Network Methods:**
- `likeReel(reelId:)` - POST request to like endpoint
- `dislikeReel(reelId:)` - DELETE request to dislike endpoint

---

### 7. **VideoPlayerManager** (Video Playback)
**File:** `ReelsViewModel.swift` (nested class)

**Architecture Pattern:** ObservableObject

**Responsibilities:**
- AVPlayer lifecycle management
- Video loading and playback
- Auto-loop functionality
- Mute/unmute control

**State Properties:**
```swift
@Published var player: AVPlayer?
@Published var isMuted: Bool
```

**Key Methods:**
- `loadAndPlay(url:)` - Loads video URL and starts playback
- `stopAndClean()` - Stops playback and releases resources
- `toggleMute()` - Toggles mute state

**Features:**
- Prevents reloading same video URL
- Auto-loops on playback completion
- Proper cleanup on deallocation

---

### 8. **Views**

#### **LoginView**
- Email/password input fields
- Login button (disabled when form invalid)
- Error message display
- Navigation to FeedView on successful login

#### **FeedView**
- Header with logout button
- Scrollable feed of posts
- Pull-to-refresh functionality
- Bottom navigation bar (Feed/Reels tabs)
- Toast message overlay
- Error state with retry button

#### **PostView**
- User profile image and name
- Post image (AsyncImage)
- Action buttons (like, comment, share, bookmark)
- Like count display
- Comments placeholder

#### **ReelsView**
- Header with logout button
- Vertical paging ScrollView
- Full-screen video players
- Bottom navigation bar
- Toast message overlay
- Error state with retry button

#### **ReelPlayerView**
- VideoPlayer (AVKit)
- User info overlay
- Action buttons (like, comment, share, mute)
- Auto-play when visible
- Auto-pause when not visible

---

## Data Flow Diagrams

### Feed Fetch Flow

```
┌─────────────┐
│  FeedView   │
│  .task {}   │
└──────┬──────┘
       │
       │ await fetchFeed()
       ▼
┌─────────────────────┐
│  FeedViewModel      │
│  fetchFeed() async  │
└──────┬──────────────┘
       │
       │ 1. Set isLoading = true
       │
       │ 2. URLSession.shared.data(from: feedURL)
       ▼
┌─────────────────────┐
│   API Endpoint      │
│  GET /user/feed     │
└──────┬──────────────┘
       │
       │ JSON Response
       ▼
┌─────────────────────┐
│  JSONDecoder        │
│  FeedResponse       │
└──────┬──────────────┘
       │
       │ feedResponse.feed
       ▼
┌─────────────────────┐
│  CoreDataManager    │
│  savePosts()        │
│  ┌────────────────┐ │
│  │ context.perform│ │
│  │ 1. clearAll    │ │
│  │ 2. Insert new  │ │
│  │ 3. saveContext │ │
│  └────────────────┘ │
└──────┬──────────────┘
       │
       │ Success
       ▼
┌─────────────────────┐
│  MainActor.run      │
│  posts = feed       │
│  isLoading = false  │
└──────┬──────────────┘
       │
       │ @Published update
       ▼
┌─────────────┐
│  FeedView   │
│  UI Update  │
└─────────────┘

ERROR PATH:
       │
       │ catch error
       ▼
┌─────────────────────┐
│  CoreDataManager    │
│  fetchPosts()       │
│  (cached data)      │
└──────┬──────────────┘
       │
       │ cachedPosts
       ▼
┌─────────────────────┐
│  MainActor.run      │
│  if !empty:         │
│    posts = cached   │
│    showToast()      │
│  else:              │
│    errorMessage     │
└─────────────────────┘
```

### Like Toggle Flow (Optimistic Update)

```
┌─────────────┐
│  PostView   │
│  Like Button│
└──────┬──────┘
       │
       │ onLike closure
       ▼
┌─────────────────────┐
│  FeedViewModel      │
│  toggleLike() async │
└──────┬──────────────┘
       │
       │ 1. Find post index
       │ 2. Save oldState, oldCount
       │
       │ OPTIMISTIC UI UPDATE
       ▼
┌─────────────────────┐
│  MainActor.run      │
│  posts[index].      │
│    likedByUser = !  │
│  posts[index].      │
│    likeCount += 1   │
└──────┬──────────────┘
       │
       │ @Published update
       ▼
┌─────────────┐
│  FeedView   │
│  UI Update  │
│  (immediate)│
└──────┬──────┘
       │
       │ OPTIMISTIC CACHE UPDATE
       ▼
┌─────────────────────┐
│  CoreDataManager    │
│  updatePost()       │
│  (local cache)      │
└──────┬──────────────┘
       │
       │ API CALL
       ▼
┌─────────────────────┐
│  likePost() or      │
│  dislikePost()      │
│  POST/DELETE        │
└──────┬──────────────┘
       │
       │ SUCCESS PATH
       │ (no action needed)
       │
       │ ERROR PATH
       ▼
┌─────────────────────┐
│  catch error        │
│  ROLLBACK           │
└──────┬──────────────┘
       │
       │ 1. Rollback UI
       ▼
┌─────────────────────┐
│  MainActor.run      │
│  posts[index] =     │
│    oldState/Count   │
└──────┬──────────────┘
       │
       │ 2. Rollback Cache
       ▼
┌─────────────────────┐
│  CoreDataManager    │
│  updatePost()       │
│  (revert to old)    │
└──────┬──────────────┘
       │
       │ 3. Show Error Toast
       ▼
┌─────────────────────┐
│  showToastMessage() │
│  "Unable to update" │
└─────────────────────┘
```

### Reels Video Playback Flow

```
┌─────────────────────┐
│  ReelsView          │
│  ScrollView         │
│  (vertical paging)   │
└──────┬──────────────┘
       │
       │ onChange(scrollPosition)
       ▼
┌─────────────────────┐
│  currentIndex       │
│  (visible reel)     │
└──────┬──────────────┘
       │
       │ isVisible = (index == currentIndex)
       ▼
┌─────────────────────┐
│  ReelPlayerView     │
│  .onChange(isVisible)│
└──────┬──────────────┘
       │
       │ if newValue == true
       ▼
┌─────────────────────┐
│  VideoPlayerManager │
│  loadAndPlay(url)   │
│  ┌────────────────┐ │
│  │ 1. Check if    │ │
│  │    same URL    │ │
│  │ 2. stopAndClean│ │
│  │ 3. Create      │ │
│  │    AVPlayerItem│ │
│  │ 4. Setup loop  │ │
│  │    observer    │ │
│  │ 5. player.play │ │
│  └────────────────┘ │
└──────┬──────────────┘
       │
       │ if newValue == false
       ▼
┌─────────────────────┐
│  VideoPlayerManager │
│  stopAndClean()     │
│  ┌────────────────┐ │
│  │ 1. Remove      │ │
│  │    observer    │ │
│  │ 2. player.pause│ │
│  │ 3. player = nil│ │
│  └────────────────┘ │
└─────────────────────┘
```

---

## API Endpoints

### Base URL
```
https://dfbf9976-22e3-4bb2-ae02-286dfd0d7c42.mock.pstmn.io
```

### 1. **GET /user/feed**
**Purpose:** Fetch user's feed posts

**Request:**
```
GET /user/feed
```

**Response:**
```json
{
  "feed": [
    {
      "post_id": "string",
      "user_name": "string",
      "user_image": "string (URL)",
      "post_image": "string (URL)",
      "like_count": 0,
      "liked_by_user": false
    }
  ]
}
```

**Used By:**
- `FeedViewModel.fetchFeed()`

**Error Handling:**
- Falls back to cached Core Data posts
- Shows toast: "No network. Showing cached data."
- If no cache: Shows error message

---

### 2. **GET /user/reels**
**Purpose:** Fetch user's reels

**Request:**
```
GET /user/reels
```

**Response:**
```json
{
  "reels": [
    {
      "reel_id": "string",
      "user_name": "string",
      "user_image": "string (URL)",
      "reel_video": "string (URL)",
      "like_count": 0,
      "liked_by_user": false
    }
  ]
}
```

**Used By:**
- `ReelsViewModel.fetchReels()`

**Error Handling:**
- Falls back to cached Core Data reels
- Shows toast: "No network. Showing cached data."
- If no cache: Shows error message

---

### 3. **POST /user/like**
**Purpose:** Like a post or reel

**Request:**
```
POST /user/like
Content-Type: application/json

{
  "like": true,
  "post_id": "string"  // or "reels_id" for reels
}
```

**Response:**
```
200-299: Success
Other: Error
```

**Used By:**
- `FeedViewModel.likePost(postId:)`
- `ReelsViewModel.likeReel(reelId:)`

**Request Body Models:**
- Posts: `LikeRequest` (uses `post_id`)
- Reels: `ReelLikeRequest` (uses `reels_id`)

---

### 4. **DELETE /user/dislike**
**Purpose:** Unlike a post or reel

**Request:**
```
DELETE /user/dislike
Content-Type: application/json

{
  "like": false,
  "post_id": "string"  // or "reels_id" for reels
}
```

**Response:**
```
200-299: Success
Other: Error
```

**Used By:**
- `FeedViewModel.dislikePost(postId:)`
- `ReelsViewModel.dislikeReel(reelId:)`

---

## Navigation Flow

```
┌─────────────────┐
│  InstaCloneApp  │
│  (Entry Point)  │
└────────┬────────┘
         │
         │ Root View
         ▼
┌─────────────────┐
│   LoginView     │
│  ┌───────────┐  │
│  │ LoginVM   │  │
│  └───────────┘  │
└────────┬────────┘
         │
         │ .navigationDestination
         │ (when isLoggedIn == true)
         ▼
┌─────────────────┐
│   FeedView      │
│  ┌───────────┐  │
│  │ FeedVM    │  │
│  └───────────┘  │
│  ┌───────────┐  │
│  │ LoginVM   │  │
│  │ (shared)  │  │
│  └───────────┘  │
└────────┬────────┘
         │
         │ Bottom Tab Navigation
         │ (Reels button)
         ▼
┌─────────────────┐
│   ReelsView     │
│  ┌───────────┐  │
│  │ ReelsVM   │  │
│  └───────────┘  │
│  ┌───────────┐  │
│  │ LoginVM   │  │
│  │ (shared)  │  │
│  └───────────┘  │
└────────┬────────┘
         │
         │ Bottom Tab Navigation
         │ (Feed button) or dismiss()
         │
         └─────────┐
                   │
                   ▼
         ┌─────────────────┐
         │   FeedView      │
         │   (back)        │
         └─────────────────┘

LOGOUT FLOW:
         │
         │ Logout button (anywhere)
         ▼
┌─────────────────┐
│  LoginViewModel │
│  logout()       │
│  ┌───────────┐  │
│  │ Clear     │  │
│  │ UserDefaults│ │
│  │ isLoggedIn│  │
│  └───────────┘  │
└────────┬────────┘
         │
         │ dismiss() + isLoggedIn = false
         ▼
┌─────────────────┐
│   LoginView     │
│   (restored)    │
└─────────────────┘
```

**Navigation Details:**
- **LoginView → FeedView:** Automatic via `.navigationDestination(isPresented: $viewModel.isLoggedIn)`
- **FeedView → ReelsView:** Via bottom tab button using `.navigationDestination(isPresented: $atReels)`
- **ReelsView → FeedView:** Via bottom tab button or `dismiss()` environment action
- **Anywhere → LoginView:** Via logout button that calls `viewModel.logout()` and `dismiss()`

---

## Threading Model

### Current Threading Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    MAIN THREAD                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  SwiftUI Views (@Published updates)              │  │
│  │  - LoginView, FeedView, ReelsView                │  │
│  │  - UI updates via MainActor.run                   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Core Data View Context                          │  │
│  │  - Main queue context                            │  │
│  │  - Must be accessed from main thread             │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                            │
                            │ async/await
                            ▼
┌─────────────────────────────────────────────────────────┐
│              BACKGROUND THREADS (URLSession)            │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Network Calls                                   │  │
│  │  - URLSession.shared.data()                     │  │
│  │  - Runs on background thread                    │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                            │
                            │ await MainActor.run
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    MAIN THREAD                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  UI Updates                                       │  │
│  │  - @Published properties                         │  │
│  │  - View updates                                  │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Thread Safety Analysis

#### ✅ **Thread-Safe Operations:**

1. **UI Updates:**
   ```swift
   await MainActor.run {
       posts = feedResponse.feed
       isLoading = false
   }
   ```
   - All UI updates use `MainActor.run`
   - Ensures main thread execution

2. **Save Operations:**
   ```swift
   func savePosts(_ posts: [Post]) {
       context.perform {  // ✅ Thread-safe
           // ... operations
       }
   }
   ```
   - Uses `context.perform` which handles thread safety

#### ⚠️ **Thread-Unsafe Operations:**

1. **Fetch Operations:**
   ```swift
   func fetchPosts() -> [Post] {
       // ⚠️ Direct context access - NOT thread-safe
       let postEntities = try context.fetch(request)
       // ...
   }
   ```
   - Called from async contexts (may not be on main thread)
   - **Risk:** Crashes or data corruption

2. **Update Operations:**
   ```swift
   func updatePost(_ post: Post) {
       // ⚠️ Direct context access - NOT thread-safe
       let results = try context.fetch(request)
       // ...
   }
   ```
   - Called from async contexts (may not be on main thread)
   - **Risk:** Crashes or data corruption

### Threading Flow Example (Feed Fetch)

```
Background Thread (URLSession)
    │
    │ async fetchFeed()
    │
    ├─► URLSession.shared.data()  [Background]
    │
    ├─► JSONDecoder.decode()      [Background]
    │
    ├─► coreDataManager.savePosts() [⚠️ May be background]
    │   └─► context.perform { }    [✅ Thread-safe wrapper]
    │
    └─► await MainActor.run {      [✅ Main thread]
        posts = feedResponse.feed
        isLoading = false
    }
```

### Threading Flow Example (Like Toggle)

```
Background Thread
    │
    │ async toggleLike()
    │
    ├─► await MainActor.run {      [✅ Main thread]
    │   posts[index].likedByUser = newState
    │   }
    │
    ├─► coreDataManager.updatePost() [⚠️ May be background]
    │   └─► context.fetch()          [❌ NOT thread-safe!]
    │
    ├─► likePost() API call         [Background]
    │
    └─► await MainActor.run {      [✅ Main thread]
        // Rollback if error
    }
```

---

## Core Data Schema

### Entity: PostEntity

```
PostEntity
├── id: String? (optional)
├── userName: String? (optional)
├── userImage: String? (optional)
├── postImage: String? (optional)
├── likeCount: Int32 (default: 0)
└── likedByUser: Bool
```

**Relationships:** None

**Usage:**
- Caches feed posts for offline access
- Stores like state and counts
- Replaced entirely on each fetch (clear-all-then-insert pattern)

---

### Entity: ReelEntity

```
ReelEntity
├── id: String? (optional)
├── userName: String? (optional)
├── userImage: String? (optional)
├── reelVideo: String? (optional)
├── likeCount: Int32 (default: 0)
└── likedByUser: Bool
```

**Relationships:** None

**Usage:**
- Caches reels for offline access
- Stores like state and counts
- Replaced entirely on each fetch (clear-all-then-insert pattern)

---

### Core Data Operations

#### Save Pattern (Replace-All):
```
1. Fetch all existing entities
2. Batch delete all
3. Insert new entities
4. Save context
```

#### Fetch Pattern:
```
1. Create NSFetchRequest
2. Add sort descriptor (by id, ascending)
3. Execute fetch
4. Map entities to domain models
5. Return array
```

#### Update Pattern:
```
1. Fetch entity by id (predicate)
2. Update all properties
3. Save context
```

---

## Upstream & Downstream Connections

### Upstream (Data Sources)

```
┌─────────────────────────────────────────────────────────┐
│                    UPSTREAM                             │
└─────────────────────────────────────────────────────────┘

1. Mock API Server (Postman Mock)
   └─► Base URL: https://dfbf9976-22e3-4bb2-ae02-286dfd0d7c42.mock.pstmn.io
       ├─► GET /user/feed
       ├─► GET /user/reels
       ├─► POST /user/like
       └─► DELETE /user/dislike

2. UserDefaults (Local Storage)
   └─► Keys:
       ├─► "isLoggedIn" (Bool)
       └─► "userEmail" (String)

3. Core Data (Local Cache)
   └─► Entities:
       ├─► PostEntity
       └─► ReelEntity
```

### Downstream (Data Consumers)

```
┌─────────────────────────────────────────────────────────┐
│                   DOWNSTREAM                             │
└─────────────────────────────────────────────────────────┘

1. SwiftUI Views
   ├─► LoginView
   │   └─► Consumes: LoginViewModel state
   │
   ├─► FeedView
   │   ├─► Consumes: FeedViewModel.posts
   │   ├─► Consumes: FeedViewModel.isLoading
   │   ├─► Consumes: FeedViewModel.errorMessage
   │   └─► Consumes: FeedViewModel.showToast
   │
   └─► ReelsView
       ├─► Consumes: ReelsViewModel.reels
       ├─► Consumes: ReelsViewModel.isLoading
       ├─► Consumes: ReelsViewModel.errorMessage
       ├─► Consumes: ReelsViewModel.showToast
       └─► Consumes: VideoPlayerManager.player

2. AVKit Framework
   └─► VideoPlayer
       └─► Consumes: AVPlayer from VideoPlayerManager

3. URLSession
   └─► Network Layer
       └─► Consumes: API endpoints
```

### Data Flow Summary

```
UPSTREAM FLOW:
API Server → URLSession → ViewModel → CoreDataManager → Core Data
UserDefaults → LoginViewModel → LoginView

DOWNSTREAM FLOW:
Core Data → CoreDataManager → ViewModel → @Published → SwiftUI Views
LoginViewModel → @Published → LoginView
VideoPlayerManager → @Published → ReelPlayerView → VideoPlayer
```

### Dependency Graph

```
InstaCloneApp
    │
    ├─► PersistenceController (Singleton)
    │   └─► NSPersistentContainer
    │       └─► viewContext
    │
    └─► LoginView
        │
        ├─► LoginViewModel
        │   └─► UserDefaults
        │
        └─► FeedView (on login)
            │
            ├─► FeedViewModel
            │   ├─► CoreDataManager.shared
            │   │   └─► PersistenceController.shared
            │   │       └─► viewContext
            │   │
            │   └─► URLSession
            │       └─► Mock API Server
            │
            └─► ReelsView (via navigation)
                │
                └─► ReelsViewModel
                    ├─► CoreDataManager.shared
                    │   └─► PersistenceController.shared
                    │       └─► viewContext
                    │
                    ├─► VideoPlayerManager
                    │   └─► AVPlayer (AVKit)
                    │
                    └─► URLSession
                        └─► Mock API Server
```

---

## Key Design Patterns

### 1. **Singleton Pattern**
- `PersistenceController.shared`
- `CoreDataManager.shared`

### 2. **MVVM (Model-View-ViewModel)**
- Views: LoginView, FeedView, ReelsView
- ViewModels: LoginViewModel, FeedViewModel, ReelsViewModel
- Models: Post, Reel, PostEntity, ReelEntity

### 3. **ObservableObject / @Published**
- Reactive state management
- Automatic UI updates on state changes

### 4. **Optimistic UI Updates**
- Immediate UI feedback
- Rollback on API failure
- Better user experience

### 5. **Repository Pattern (CoreDataManager)**
- Centralized data access
- Abstraction over Core Data
- Single source of truth

### 6. **Dependency Injection**
- ViewModels passed to Views
- Shared LoginViewModel across views
- Environment values for Core Data context

---

## Summary

**InstaClone** is a well-structured Instagram-like app with:
- ✅ Clean MVVM architecture
- ✅ Offline-first caching strategy
- ✅ Optimistic UI updates
- ✅ Proper async/await usage
- ⚠️ Some threading issues in Core Data access
- ✅ Good separation of concerns
- ✅ Reusable components

**Areas for Improvement:**
1. Fix thread safety in `fetchPosts()` and `updatePost()` methods
2. Add proper error logging framework
3. Consider adding network reachability checks
4. Add unit tests for ViewModels
5. Consider pagination for large feeds
