package input;

import h2d.Interactive;
import h2d.Text;
import hxd.res.DefaultFont;

/**
 * Android touch input: a virtual D-pad (4 buttons) at the bottom-right corner.
 * Holding a button keeps the direction active, like holding a key on desktop.
 * Scale is derived from the reference 1024x768 layout so it stays usable on
 * any phone resolution.
 */
class TouchInput implements InputController {
	static inline var REF_W = 1024.0;
	static inline var REF_H = 768.0;

	var s2d:h2d.Scene;
	var dx = 0;
	var dy = 0;
	var buttons:Array<Interactive> = [];
	var backgrounds:Array<h2d.Graphics> = [];

	public function new(s2d:h2d.Scene) {
		this.s2d = s2d;
		buildDpad();
	}

	function currentScale():Float {
		return Math.min(s2d.width / REF_W, s2d.height / REF_H);
	}

	function buildDpad() {
		for (b in buttons) b.remove();
		for (g in backgrounds) g.remove();
		buttons = [];
		backgrounds = [];

		var s = currentScale();
		var size = Std.int(48 * s);
		var gap = Std.int(10 * s);
		var margin = 20 * s;
		var cx = s2d.width - (size * 3 + gap * 2) - margin;
		var cy = s2d.height - (size * 3 + gap * 2) - margin;

		function add(x:Float, y:Float, dirX:Int, dirY:Int, label:String) {
			// Visible background: Graphics quad (geometry-based, robust on GLES).
			var bg = new h2d.Graphics(s2d);
			bg.beginFill(0xFF335588, 1);
			bg.drawRect(x, y, size, size);
			bg.endFill();
			// Hit area on top (transparent - the background is drawn above).
			var b = new Interactive(size, size, s2d);
			b.x = x;
			b.y = y;
			b.onPush = function(_) {
				dx = dirX;
				dy = dirY;
			};
			b.onRelease = function(_) {
				dx = 0;
				dy = 0;
			};
			b.onReleaseOutside = function(_) {
				dx = 0;
				dy = 0;
			};
			var t = new Text(DefaultFont.get(), b);
			t.text = label;
			t.scale(s);
			t.x = (b.width - t.textWidth * t.scaleX) / 2;
			t.y = (b.height - t.textHeight * t.scaleY) / 2;
			buttons.push(b);
			backgrounds.push(bg);
		}

		add(cx + size + gap, cy, 0, -1, "^");
		add(cx + size + gap, cy + 2 * (size + gap), 0, 1, "v");
		add(cx, cy + size + gap, -1, 0, "<");
		add(cx + 2 * (size + gap), cy + size + gap, 1, 0, ">");
	}

	public function update(dt:Float) {}

	/** Rebuild the D-pad when the screen size changes. */
	public function onResize() buildDpad();

	public function directionX() return dx;
	public function directionY() return dy;
	public function helpText() return "Use the on-screen arrows to move.";
}
