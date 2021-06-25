# duse
duse == (D)irectory use - A shim based directory management workflow. AKA a hot cache.

This is particularly useful for video editing, while keeping the primary storage on a NAS.

## How it fits together

* Context: The type of contents that you want to manage. Eg photo shoots, or audio clips.
* Source: The single source of truth for a given piece of content within a context.
* ReadCache: The short term storage where contents will be stored while it's in use.
* Workspace: The virtual location that you interact with.

Worked example:

You are starting a new project called exampleProject, and have recently done some photo-shoots `000`, `001`, and `002` for it. They are stored on a network share in `/mnt/shoots` and `/mnt/oldShoots`, and your new project is stored in `~/projects/exampleProject`. You have a local cache in `~/localCache`.

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

Let's see what we can use.
```bash
duse --listAvailable
```

Let's use 000.
```bash
duse --use 000
duse --list
```

Or! How about when we want to get the two most recent things?
```bash
duse --listAvailable | tail -n 2 | duse --use
duse --list
```

#### Switching between the source and the cache

Let's switch to cache for 001.
```bash
duse --cache 001
duse --list
```

In fact, let's switch everything to using the cache.
```bash
duse --cache
duse --list
```

Let's switch 002 back to the source.
```bash
duse --source 002
duse --list
```

Right! We're done with this project, let's switch everything back to the source.
```bash
duse --source
```

#### Switching between the sources and the caches project wide

Imagine you have have several contexts in your project: `shoots`, `audio` and `video`.

The key difference is that you need to get into the project directory, and not an individual workspace within that project:

```bash
cd ~/projects/example
duse --info
```

Now we can switch between cache and source, project wide.
```bash
duse --cache
```

```bash
duse --source
```

#### Other workflow stuff

If the source gets updated, you can update the cache like this.
```bash
duse --sync
```

## Requirements

* bash.
* rsync.
* [realpath](https://man7.org/linux/man-pages/man1/realpath.1.html).
