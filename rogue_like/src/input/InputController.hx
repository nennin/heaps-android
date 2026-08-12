package input;

/**
 * Platform-agnostic input abstraction.
 *
 * A controller reports a continuous movement direction (-1/0/1 per axis),
 * which the game logic polls each frame. Desktop uses the keyboard; Android
 * uses an on-screen touch D-pad. The game code never touches hxd.Key directly.
 */
interface InputController {
	/** Poll input / update any on-screen UI. Call once per frame before the game update. */
	function update(dt:Float):Void;
	/** Horizontal direction: -1 left, 0 none, +1 right. */
	function directionX():Int;
	/** Vertical direction: -1 up, 0 none, +1 down. */
	function directionY():Int;
	/** Instructions text appropriate for this platform. */
	function helpText():String;
}
