# Cozy-Cafe-Game
Cozy Café was born from a simple idea: what if a game could feel relaxing and challenging at the same time?
A lot of mobile games lean too hard in one direction — either they're so calm they lose their spark, or so intense they stop being fun. Cozy Café tries to find the sweet spot in between. The warm visuals, coffee shop atmosphere, and gentle sounds are designed to feel soothing, while the ticking patience bars and growing customer queues keep you just engaged enough to stay on your toes.
The goal was never to make a stressful game. It was to make one that feels like a good cup of coffee — comforting, familiar, with just enough of a kick to keep you going.

What the Game Does:
You play as a café owner managing a small dining room with three tables. Customers queue up and get seated automatically. Each customer has a visible patience bar that drains in real time — serve their order before it hits zero or they walk out, costing you coins and resetting your streak.
Core loop:

Customers arrive with orders (1–3 items depending on level)
Tap menu buttons to serve matching items
Complete full orders for tips and bonuses
Reach the level goal (customers served) to advance
Lose too many customers in one level → Try Again screen


What each AI was most useful for:

Claude — Long, context-heavy code generation; reasoning through timer-based game loops and async state mutation; organizing large SwiftUI files with MARK sections; writing the particle system logic.

ChatGPT — Quick syntax questions, explaining SwiftUI concepts, generating boilerplate code for models and view structures.

Gemini — Debugging specific SwiftUI behaviors, cross-referencing Apple API documentation, offering alternative implementations when another tool's suggestion didn't compile.

