# Live RNGLR incrementality

Phase 26 connects RNGLR-Parser's GSS and forest reuse arenas to the real RNGLR
driver. `RNGLRIncrementalSession` owns one grammar-bound document runtime and
accepts stable identities for the non-EOF tokens produced by a language kit.

For an edit, the session finds the unchanged token prefix and resumes at its
first changed token. The retained boundary contains only shift edges. GSS
nodes and BSR completions created by reductions at that position are removed
because reductions are selected by lookahead; the native reduction fixed point
then rebuilds them with the new token. Earlier GSS topology and BSR facts remain
live engine state.

Operational evidence distinguishes:

- retained, removed, and rebuilt `gssNodes`;
- retained, removed, and rebuilt BSR-backed `forestNodes`; and
- stable versus regenerated `tokens`.

Differential tests compare the resumed BSR and portable SPPF with a clean
RNGLR parse, cover unchanged documents, identity validation, and editing
through a rejected intermediate document. PL/0's ecosystem comparison now
keeps a live RNGLR session and passes the stable identities from its shared
lexer instead of constructing a fresh parser for every comparison.

The public SPPF is currently projected afresh from the combined retained and
rebuilt BSR set. Thus Phase 26 claims native GSS and BSR fact reuse, not object
identity for the returned `SPPFGraph` projection.

As with live Earley incrementality, only a contiguous prefix is reused. A
converged suffix may have different input positions, GSS state/span identities,
and SPPF extents. Relocating such state safely remains future work.
