# duse
duse == (D)irectory use - A shim based directory management workflow for proactive caching.

This is particularly useful for video editing, while keeping the primary storage on a NAS. It's also useful if you need to travel, and know that you have all of the media you need for your work, without having to blindly copy everything.

## How it fits together

* Context: The type of contents that you want to manage. Eg photo shoots, or audio clips.
* Source: The single source of truth for a given piece of content within a context. You can actually have multiple sources that make up the single source of truth. Eg primary storage for your most accessed media, with archive storage for old media that you don't need as often.
* ReadCache: The short term disposable storage where contents will be stored while it's in use.
* Workspace: The virtual location that you interact with.

Worked example:

You are starting a new project called exampleProject, and have recently done some photo-shoots `000`, `001`, `002`, `003`, `004`, `005`, and `006` for it. `004`-`006` are stored on a network share in `/mnt/shoots`, while `001`-`001` are stored in `/mnt/oldShoots`, and your new project is stored in `~/projects/exampleProject`. You have a local cache in `~/localCache`.

### Set up the context

With this being a fresh setup, we need to set up the context:

```bash
duse --addContext shoots "A collection of photo/video shoots."
```

Now, let's add the sources to the `shoots` context as `s1` and `s2`:

```bash
duse --addSource shoots /mnt/shoots s1 "Most recent photo-shoots." 
duse --addSource shoots /mnt/oldShoots s2 "Archived photo-shoots." 
```

Let's specify where we want to cache the `shoots` context:

```bash
duse --setCache shoots ~/localCache
```

### Set up the workspace that uses the context

Now let's create the `shootsWS` workspace that uses the `shoots` context.
```bash
mkdir -p ~/projects/example
cd ~/projects/example
duse --createWorkspace shoots shootsWS
```

At this point, you're set up, and don't need to think about the context anymore.

### Using the example project

#### Get some data associated with the project

By entering the workspace, `duse` knows which context to get information from.

```bash
cd ~/projects/example/shoots
duse --info
duse --list
```

At this opint, you'll see information about the `shoots` context, and an empty list of directory entries.

Let's see what we can use.
```bash
duse --listAvailable
```

Let's use 001.
```bash
duse --use 001
duse --list
```

You should now see something like this
```
Entry  Accessible  Type      Location
001    Yes         Uncached  archiveShoots
```

Or! How about when we want to get the two most recent things?
```bash
duse --listAvailable | tail -n 2 | duse --use
duse --list
```

```
Entry  Accessible  Type      Location
001    Yes         Uncached  archiveShoots
005    Yes         Uncached  primaryShoots
006    Yes         Uncached  primaryShoots
```

#### Switching between the source and the cache

Let's switch to cache for 001.
```bash
duse --cache 001
duse --list
```

```
Entry  Accessible  Type      Location
001    Yes         Cached    
005    Yes         Uncached  primaryShoots
006    Yes         Uncached  primaryShoots
```

In fact, let's switch everything to using the cache. This will cache/sync them, and this same cache will be used for all projects that use the same context. So there will be no duplication in the cache.
```bash
duse --cache
duse --list
```

```
Entry  Accessible  Type    Location
001    Yes         Cached  
005    Yes         Cached  
006    Yes         Cached  
```

Let's switch 002 back to the source.
```bash
duse --uncache 005
duse --list
```

```
Entry  Accessible  Type      Location
001    Yes         Cached    
005    Yes         Uncached  primaryShoots
006    Yes         Cached    
```

Right! We're done with this project, let's switch everything back to the source.
```bash
duse --uncache
```

```
Entry  Accessible  Type      Location
001    Yes         Uncached  archiveShoots
005    Yes         Uncached  primaryShoots
006    Yes         Uncached  primaryShoots
```

Cool. So we have pretty tight control over what is cached, and when. In reality, you probably want to `--cache` or `--uncache` and entire project, with all of its workspaces, in one go. Let's look at that next.

#### Switching between the sources and the caches project wide

Imagine you have have several contexts in your project: `shoots`, `audio` and `video`.

The key difference is that you need to get into the project directory, and not an individual workspace within that project:

```bash
cd ~/projects/example
```

Now we can switch between cache and source, project wide (all workspaces will be switched).
```bash
duse --cache
```

```bash
duse --uncache
```

#### Other workflow stuff

If the source gets updated, you can update the cache like this. This will also clean out any obsolete cache that is no longer needed because something has been manually removed from a workspace without using `--unuse`.

```bash
duse --sync
```

## Requirements

### For operation

* [bash](https://man7.org/linux/man-pages/man1/bash.1.html).
* [rsync](https://man7.org/linux/man-pages/man1/rsync.1.html).
* [realpath](https://man7.org/linux/man-pages/man1/realpath.1.html).
* [readlink](https://man7.org/linux/man-pages/man1/readlink.1.html).

### For development of duse

* [shest](https://github.com/ksandom/shest) for unit testing.
* [shellcheck](https://github.com/koalaman/shellcheck). for linting.
