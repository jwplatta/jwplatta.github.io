---
layout: post
title:  "Semantic Search for Obsidian"
date:   2024-03-04 10:00:00 -0500
categories: [machine-learning]
tags: [nlp, semantic search, obsidian, node.js, sqlite, text embeddings]
math: true
toc: true
img_path: /assets/img/posts/
---
One of my favorite tools these days is the note taking app [Obsidian](https://obsidian.md/). Obsidian provides a lot of nice functionality for organizing and searching through notes such as tagging with keywords and fuzzy searching. However, I'm an *aggressive* notetaker. I like to jot things down quickly and move on with my work rather than try to slot every note into the correct spot. So finding specific items that I can vaguely recall is often tricky because of the nuance and context sensitivity of the query. So, as a quick project, I wanted to implement a simple version of semantic search over my notes. So, I put together a personal Obsidian plugin.[reference the other implementation here]

The strategy for implementing semantic search is straightforward. First the notes are split into smaller chunks of texts. These chunks are converted into embeddings, or a vectors of real numbers, using a large language model (LLM). Then to compute searches, the distance between the embeddings of the notes is compared to the embedding of a query. The notes closest to the query are returned as the result of the search. My implementation uses SQLite with the extension `sqlite-vss` for storing and searching embedding. It generates the embeddings using `Xenova/all-MiniLM-L6-v2` model that's available in the `Transformers.js` library.

I chose this implementation with a handful of constraints in mind. I wanted to make it easy to possibly share the plugin in the future. So, I prioritized minimizing the resources that it would need and tried to avoid external dependencies for storing or generating the embeddings. To generate the embeddings I opted for the `Xenova/all-MiniLM-L6-v2` over other models such as those offered by OpenAI. The `MiniLM` models are open source and small enough to store locally while also generating performant embeddings.

SQLite was a good choice for the vector datastore. It's lightweight and has available libraries optimized for Node.js environments such as `better-sqlite3`. Additionally, the `sqlite-vss` extension is sufficiently fast even if not as fast alternatives like Pinecone or even postgres with `pg_vector`. Moreover, the extension has a Node.js interface for interacting with the optimized vector search functionality. However, due to the safety constraints enforced by the Obsidian Electron app, I ended up implementing the functionality for generating, storing, and searching the embedding vectors in a Node.js backend server with an `express` interface exposed on a port known by the Obsidian client.

So, the final implementation had these core components:

- **Backend Server:** A Node.js server using `express` was set up to interact with the vector datastore. This server handled the generating the embeddings and facilitated the search operations.
- **Data Storage:** Embedding vectors were stored as BLOBs in a SQLite table with file details. The sqlite-vss extension uses a separate table to index the embedding for efficient vector searches.
- **Obsidian UI:** The plugin interfaced with Obsidian's `SuggestModal` to provide a seamless semantic search experience. Users could type in queries, and relevant notes or text chunks were suggested in real-time.

The basic workflow for using the semantic search feature in Obsidian uses a few commands.
1. **Generate Embeddings:** The first step involved generating embeddings for the entire vault.
2. **Update the Index:** After generating the embeddings, the embeddings are indexed for searching.
3. **Search:** With the index updated, users can perform semantic searches to find relevant notes based on the meaning of their queries.

Overall, the design choices hopefully leave the implementation open to possibly bundling all the resources for generating, storing, and searching using the embeddings with the Obsidian plugin. If I were to try to remove the dependency on the Node.js backend server, I would need to rebuild the SQLite module to target the Electron runtime because Electron uses a different V8 engine version than Node.js. Another future goal is to implement a regular schedule for updating the embeddings. For example, it might make sense to update the embeddings after specific events, such as when a file is saved. This would ensure that the search index remains up-to-date and reflective of the latest changes in the user's notes.