# Animation Matrix

This document acts as the definitive manifest for all animations required by the `AnimationController` and asset pipeline.

## 1. Batting Animations
All batting animations must exist in both `Right-Handed (RH)` and `Left-Handed (LH)` variants (can be achieved via simple Sprite flipping in the `AnimationController` if lighting permits).

- `idle_stance`: Default looping idle.
- `backlift`: Preparation frame immediately before a shot.
- `defensive_forward`: Solid front-foot block.
- `defensive_back`: Solid back-foot block.
- `cover_drive`: Fluid front-foot drive.
- `straight_drive`: Front-foot drive down the ground.
- `cut`: Back-foot square shot.
- `pull`: Back-foot aggressive cross-bat shot.
- `hook`: High-bounce aggressive shot.
- `sweep`: Front-foot kneeling cross-bat shot.
- `lofted_drive`: Aggressive aerial front-foot shot.
- `leave`: Lifting the bat out of the way.
- `play_and_miss`: Beaten swing.
- `out_reaction`: Dropping bat / walking off.

## 2. Bowling Animations
All bowling animations must exist in both `Right-Arm` and `Left-Arm` variants.

### Pace
- `pace_idle`: Standing at the top of the mark.
- `pace_run_up`: Running loop (4-8 frames).
- `pace_gather`: Pre-delivery jump.
- `pace_release`: Arm extended, ball leaving hand.
- `pace_follow_through`: Momentum carry post-release.

### Spin
- `spin_idle`: Standing.
- `spin_walk_up`: Slow approach.
- `spin_release`: Torso twist and release.
- `spin_follow_through`: Pivot post-release.

## 3. Fielding Animations
- `idle`: Ready position.
- `standing_catch`: Two hands up/down.
- `diving_catch_left`: Horizontal extension.
- `diving_catch_right`: Horizontal extension.
- `ground_stop`: Sliding/kneeling block.
- `throw`: Overarm hurl.
- `keeper_stance`: Crouched behind stumps.
- `keeper_take`: Catching the ball.
- `keeper_stump`: Whipping the bails.

## 4. Umpire Signals
- `idle`: Hands clasped.
- `out`: Raised finger.
- `not_out`: Head shake / cross arms (optional).
- `boundary_four`: Right arm sweeping side-to-side.
- `boundary_six`: Both arms raised straight up.
- `wide`: Both arms extended horizontally.
- `no_ball`: One arm extended horizontally.

---
See `docs/master_context.md`
