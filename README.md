# duse
duse == (D)irectory use - A shim based directory management workflow. AKA a hot cache.

This is particularly useful for video editing, while keeping the primary storage on a NAS.

## How it fits together

* Context: The type of contents that you want to manage. Eg photo shoots, or audio clips.
* Source: The single source of truth for a given piece of content within a context.
* ReadCache: The short term storage where contents will be stored while it's in use.
* Workdir: The virtual location that you interact with.

Worked example:

You are starting a new project called exampleProject, and have recently done some photo-shoots `000`, `001`, and `002` for it. They are stored on a network share in `/mnt/shoots` and `/mnt/oldShoots`, and your new project is stored in `~/projects/exampleProject`. You have a local cache in `~/localCache`.

### Set up the example

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
duse --addCache shoots ~/localCache
```

### Using the example


