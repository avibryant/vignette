Vignette
========

A simple, distributed, highly available, eventually-consistent sketch database that communicates entirely over UDP.

avi@avibryant.com

Current status
-------
Very early Ruby prototype. In extreme flux. Comments welcome. Also welcome are interoperable ports to other languages.

Data model
------
Vignette stores key/value pairs where the keys are strings and the values are sparse vectors of integers.

Values can *only* be modified via element-wise max. For example, let's say Vignette currently stores this:

````js
foo: {0: 5, 3: 7}
````

You can modify the ````foo```` key by sending this update:

````js
foo: {0: 8, 3: 2, 5: 1}
````

Vignette will now be storing this:

````js
foo: {0: 8, 3: 7, 5: 1}
````

This may seem extremely limiting, but element-wise max is surprisingly useful and versatile. Because the max operation is associative, commutative, and idempotent, updates can be performed in any order, in any combination, and any number of times. This makes building a robust, highly available distributed system much, much simpler.

There are a number of useful data structures that can be built directly on top of this primitive, including:
  - HyperLogLog for efficiently estimating unique values in a set
  - Min-Hash signatures for estimating set similarities
  - Bloom filters for estimating set membership
  - Vector clocks for maintaining exact distributed counters

Of these, Vignette has been most tuned for use with HyperLogLog, and this is likely the most practical application. However, it's important to note that this is purely a question of how the client code interprets the data; the database itself does not know or care anything about any of these specific uses.

Communication model
-------

Vignette operates async, connectionless, and peer to peer. There is only a single kind of message, which is sent via UDP from one peer to another. Conceptually, a message looks like this:

````js
{
 key: "foo",
 vector: {0: 8, 3: 7},
 ttl: 5
}
````

The details of the binary wire protocol are still TBD. However, the intent is to keep each message to a single packet (so, practically speaking, under 1500 bytes). It should support both sparse and dense vector representations, of various int sizes. One simple option would be to use [MessagePack](http://msgpack.org/).

Vignette uses a form of [gossip communication](http://en.wikipedia.org/wiki/Gossip_protocol). A Vignette node should respond to receiving a message from a given sender by:
  - If it has the key, iterate through the sent vector and:
    - For any elements in the vector where the node's current value is larger, send a message with those elements back to the sender.
    - For any elements in the vector where the node's current value is smaller, update the node's current value. Send a message with the new value for those elements forward to a randomly chosen third node.
  - If it doesn't have the key, just store the given vector, and forward the entire message to a random third node. This is really just a special case of the above.
  - If the message has an empty vector, treat it as if it listed every element as 0, which is to say: send back the node's entire vector for that key to the sender. There's no need to forward anything to a third node in this case.

In all cases, the messages sent out should have a TTL which is one lower than that of the incoming message. If the incoming message has a TTL of 0, don't send anything out. The TTL may not actually be necessary, but it's cheap to include and seems like a useful safeguard against buggy nodes, and for queries (see below).

Queries and special keys
-----------

There are several patterns in key strings that are treated specially by Vignette.

### Searches ###
A key containing the '%' character is treated as a query pattern, and a node receiving a message with that key should first find all of the keys it has stored that match that pattern (using the % as a wildcard), and then act as if it had received identical messages for all of those keys. It is probably only sensible to send a '%' message with an empty vector; this causes the receiving node to send back its full vectors for all keys matching the pattern.

### Aggregates ###
A key containing the '*' character is also treated as a query pattern, but with a single, aggregated response instead of multiple responses. In particular, the semantics are:
  - Find all of the keys which match the pattern (using * as a wildcard)
  - Combine all of their vectors with element-wise max, and treat this new vector as if it has just been sent in as a (normal, not wildcarded) message with the query pattern as its key.
  - Process the incoming message as a normal message. Often, it will have an empty vector, so send the entire combined vector back to the sender.

Note that the second step could (in fact usually will) cause a wildcarded message, with a non-empty vector, to get sent out to some third node. This means that information about aggregates will be exchanged directly as well as (and not necessarily in sync with) individual keys. This is fine, and useful, but one of the main reasons for the TTL is to stop this from continuing forever for aggregates that stop being relevant.

### Peers ###
A key that starts with "n:" represents the last known time a message has been observed from a given sender. Each node will synthesize one of these messages to itself whenever it receives a message from another node. The format of the key is "n:host:port", and the vector should have a single element which is the unix timestamp, rounded to the nearest minute. These messages follow the normal rules for forwarding and so will propagate throughout the network. A node will use these keys to decide which other nodes are active and should be used when sending out updates.

When first starting up, as long as a node knows about and can reach any other node, it can send a "n:%" message to that node to announce itself and bootstrap knowledge of the network. It's possible this should involve multicast or broadcast somehow instead of an explicit seed node, but I don't think it's impractical to have a few well known addresses that a joining node can try to contact.

Persistence
-----------

Any given node should manage its storage however it likes. Some nodes will in fact be client libraries loaded into other processes that are generating events, and so might only store a handful of keys as an optimization, to avoid sending out needless messages. Some nodes might store as many keys as they can in memory, expiring them randomly or with a LRU policy, but not persist anything. Some nodes might periodically dump their state to disk, or use LevelDB as a backing store, etc, etc. The overall system is simple enough that it should be possible to have a great many such implementations, all interoperable, and construct heterogenous networks of them according to need.