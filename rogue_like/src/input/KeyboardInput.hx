package input;

/**
 * Desktop input: arrow keys / WASD. Movement is continuous while a key is held.
 */
class KeyboardInput implements InputController {
	var dx = 0;
	var dy = 0;

	public function new() {}

	public function update(dt:Float) {
		dx = 0;
		dy = 0;
		if (hxd.Key.isDown(hxd.Key.UP) || hxd.Key.isDown(hxd.Key.W)) dy = -1;
		if (hxd.Key.isDown(hxd.Key.DOWN) || hxd.Key.isDown(hxd.Key.S)) dy = 1;
		if (hxd.Key.isDown(hxd.Key.LEFT) || hxd.Key.isDown(hxd.Key.A)) dx = -1;
		if (hxd.Key.isDown(hxd.Key.RIGHT) || hxd.Key.isDown(hxd.Key.D)) dx = 1;
	}

	public function directionX() return dx;
	public function directionY() return dy;
	public function helpText() return "Arrow keys / WASD to move.";
}
