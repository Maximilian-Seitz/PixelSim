# Pixel Sim

A Godot implementation of a cell-based simulator running on the graphics-card, capable of simulation 2D falling sand, water, and similar cells.

Inspired by Yusef28 [[1]](#1), who presents some ideas for cell behaviors, like water, fire, bees, etc., some of which are loosly replicated here.

The basic cell processing is adapted from Devlin and Schuster [[2]](#2), who describe how a conflict-free resolution of falling sand can be actualized with parallel processing. This concept is adapted for sand as-is, and other cells use the same basic framework, but different propagation rules.

## References

<a id="1">[1]</a>
[Yusef28](https://www.youtube.com/@Yusef28) (2024),
[I Made Falling Sand Games in Fragment Shaders](https://youtu.be/8Tf18MMZ-5U?si=G3Mo0VYhfy8sUypJ).

<a id="2">[2]</a>
Devlin, Jonathan and Schuster, Micah D (2021).
Probabilistic cellular automata for granular media in video games.
The Computer Games Journal, 10(1), 111-120.
