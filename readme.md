Repro for https://github.com/jessesquires/ReactiveCollectionsKit/issues/125

Creates a collection view with 100,000 items with continuously changing ids to stress the diffing algorithm.

Continuously shows & hides the list.

After a while, the app should crash with `Fatal error: Attempted to read an unowned reference but the object was already deallocated`.
