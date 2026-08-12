import input.InputController;
import input.KeyboardInput;
import input.TouchInput;

/**
 * Application entry point.
 *
 * Wires the platform-appropriate {@link InputController} (keyboard on desktop,
 * touch D-pad on Android) into the cross-platform {@link core.Roguelike} game.
 * This is the only place that branches on the runtime platform.
 */
class Main extends hxd.App {
	public static var inst:Main;

	var game:core.Roguelike;
	var input:InputController;

	static function main() {
		inst = new Main();
	}

	override function init() {
		// Resources are embedded into the binary so they work on both desktop
		// and Android (no runtime filesystem dependency).
		hxd.Res.initEmbed();

		if (Sys.systemName() == "Android")
			input = new TouchInput(s2d);
		else
			input = new KeyboardInput();

		game = new core.Roguelike(s2d, input);
	}

	override function update(dt:Float) {
		input.update(dt);
		game.update(dt);
	}

	/** Re-fit the game layout and touch UI when the window/screen resizes. */
	override function onResize() {
		super.onResize();
		if (game != null)
			game.resize();
	}
}
