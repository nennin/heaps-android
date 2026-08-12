package core;

import h2d.Bitmap;
import input.InputController;

/**
 * Cross-platform roguelike game logic.
 *
 * The map is scaled (fit-to-screen) so it is fully visible on any resolution /
 * orientation, and the world uses a fixed screen-space layout (no camera
 * follow), which also keeps the on-screen touch UI always visible.
 * Movement is driven by the injected {@link InputController} - no
 * platform-specific code lives here.
 */
class Roguelike {

	public var player:h2d.Object;
	public var playerCol:Int = 0;
	public var playerRow:Int = 0;

	final fieldSize = 32.0;
	final margin = 80.0;
	// Text sizes: glyphs fill their cell (16px font base * scale = cellSize),
	// bumped up so characters read clearly on phones. The help text is larger.
	static final GLYPH_SCALE = 2.6;
	static final HELP_SCALE = 3.0;
	final levelString = "
                                                    ###################
               ###########################          #                 #
               #                         #          #            A    #
               #                         ############                 #
               #                                                      #
               #            @            ############                 #
               #                         #          #                 #
               #                         #          #      C          #
               #                         #          ###################
               #   E                     #
               #                         #
               ###########################
    ";

	var s2d:h2d.Scene;
	var input:InputController;
	var walls:Array<{c:Int, r:Int, obj:h2d.Object}> = [];
	var howToPlayInfo:h2d.Text;
	var exitCol:Int = 0;
	var exitRow:Int = 0;
	var eObj:h2d.Object;
	var eImage:Bitmap;
	var dtCounter:Float = 0;

	var fitScale:Float = 1.0;
	var cellSize:Float = 32.0;

	public function new(s2d:h2d.Scene, input:InputController) {
		this.s2d = s2d;
		this.input = input;
		setup();
	}

	function setup() {
		computeFitScale();

		howToPlayInfo = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
		howToPlayInfo.text = input.helpText();
		howToPlayInfo.scale(HELP_SCALE * fitScale);

		// Parse the ASCII level into grid coordinates.
		var x = 0;
		var y = 0;
		for (i in 0...levelString.length) {
			var char = levelString.charAt(i);
			if (char == "\n") {
				y++;
				x = 0;
			} else if (char != " ") {
				characterToGameObject(char, x, y);
			}
			x++;
		}

		layout();
	}

	function characterToGameObject(character:String, x:Int, y:Int) {
		switch (character) {
			case "@": // player
				playerCol = x;
				playerRow = y;
			case "#": // walls
				var o = new h2d.Object(s2d);
				var t = new h2d.Text(hxd.res.DefaultFont.get(), o);
				t.text = character;
				t.scale(GLYPH_SCALE * fitScale);
				walls.push({c: x, r: y, obj: o});
			case "E": // exit marker (text) + artifact image above it
				exitCol = x;
				exitRow = y;
				eObj = new h2d.Object(s2d);
				var t = new h2d.Text(hxd.res.DefaultFont.get(), eObj);
				t.text = character;
				t.scale(GLYPH_SCALE * fitScale);
			default:
				// Decorative map markers (A, C, ...) - ignored, no logic.
		}
	}

	function computeFitScale() {
		var maxX = 0, maxY = 0, x = 0, y = 0;
		for (i in 0...levelString.length) {
			var char = levelString.charAt(i);
			if (char == "\n") {
				y++;
				x = 0;
			} else {
				if (char != " ") {
					if (x > maxX) maxX = x;
					if (y > maxY) maxY = y;
				}
				x++;
			}
		}
		var mapW = (maxX + 1) * fieldSize;
		var mapH = (maxY + 1) * fieldSize;
		fitScale = Math.min((s2d.width - margin * 2) / mapW, (s2d.height - margin * 2) / mapH);
		if (fitScale < 0.4) fitScale = 0.4;
		if (fitScale > 2) fitScale = 2;
		cellSize = fieldSize * fitScale;
	}

	function layout() {
		// Player (@) - created lazily so it can be re-laid out.
		if (player == null) {
			player = new h2d.Object(s2d);
			var t = new h2d.Text(hxd.res.DefaultFont.get(), player);
			t.text = "@";
			t.scale(GLYPH_SCALE * fitScale);
		}
		player.setPosition(margin + playerCol * cellSize, margin + playerRow * cellSize);

		for (w in walls)
			w.obj.setPosition(margin + w.c * cellSize, margin + w.r * cellSize);

		if (eObj != null)
			eObj.setPosition(margin + exitCol * cellSize, margin + exitRow * cellSize);

		// Artifact image floating above the exit.
		if (eImage == null) {
			var tile = hxd.Res.haxeLogo.toTile();
			eImage = new Bitmap(tile, s2d);
		}
		eImage.setPosition(margin + exitCol * cellSize, margin + exitRow * cellSize - 40 * fitScale);
		eImage.visible = false;

		// Help text: top-center, above the map.
		howToPlayInfo.x = (s2d.width - howToPlayInfo.textWidth * howToPlayInfo.scaleX) / 2;
		howToPlayInfo.y = 20;
	}

	/** Re-fit the layout after the window/screen changes. */
	public function resize() {
		computeFitScale();
		var ts = GLYPH_SCALE * fitScale;
		howToPlayInfo.scale(HELP_SCALE * fitScale);
		if (player != null) player.getChildAt(0).scale(ts);
		for (w in walls) w.obj.getChildAt(0).scale(ts);
		if (eObj != null) eObj.getChildAt(0).scale(ts);
		layout();
		input.onResize();
	}

	public function update(dt:Float) {
		// Grid movement while a direction is held (0.1s steps).
		dtCounter += dt;
		if (dtCounter > 0.1) {
			var dirX = input.directionX();
			var dirY = input.directionY();
			if (dirX != 0 || dirY != 0) {
				var nx = playerCol + dirX;
				var ny = playerRow + dirY;
				if (checkIfPositionIsWallFree(nx, ny)) {
					playerCol = nx;
					playerRow = ny;
					player.setPosition(margin + playerCol * cellSize, margin + playerRow * cellSize);
				}
			}
			dtCounter -= 0.1;
		}

		// Show the artifact when the player reaches the exit marker.
		if (eImage != null) {
			eImage.visible = (playerCol == exitCol && playerRow == exitRow);
			if (eImage.visible)
				eImage.rotation += dt * 2;
		}
	}

	function checkIfPositionIsWallFree(c:Int, r:Int):Bool {
		for (w in walls)
			if (w.c == c && w.r == r)
				return false;
		return true;
	}
}
