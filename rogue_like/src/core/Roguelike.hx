package core;

import h2d.Bitmap;
import input.InputController;

/**
 * Cross-platform roguelike game logic.
 *
 * Movement is driven by an injected {@link InputController}, so this file has
 * NO platform-specific code (no hxd.Key, no Android APIs). The same logic runs
 * on desktop and Android.
 */
class Roguelike {

	public var player:h2d.Object;

	final fieldSize = 32;
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
	var walls:Array<h2d.Object> = [];
	var howToPlayInfo:h2d.Object;
	var ePosition:{x:Float, y:Float};
	var eImage:Bitmap;
	var dtCounter:Float = 0;

	public function new(s2d:h2d.Scene, input:InputController) {
		this.s2d = s2d;
		this.input = input;
		setup();
	}

	function setup() {
		var t = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
		t.text = input.helpText();
		t.scale(2);
		howToPlayInfo = t;

		// Parse the ASCII level.
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

		// Camera follows the player.
		s2d.camera.anchorX = 0.5;
		s2d.camera.anchorY = 0.5;

		// Place the help text relative to the player / camera.
		var cam = s2d.camera;
		howToPlayInfo.setPosition(player.x - (cam.viewportWidth / 2), player.y - (cam.viewportHeight / 2));
	}

	function characterToGameObject(character:String, x:Float, y:Float) {
		var o = new h2d.Object(s2d);
		var t = new h2d.Text(hxd.res.DefaultFont.get(), o);
		t.text = character;
		t.scale(2);
		o.setPosition(x * fieldSize, y * fieldSize);

		switch (character) {
			case "@": // player
				player = o;
				s2d.camera.follow = player;
			case "#": // walls
				walls.push(o);
			case "E": // exit: the artifact image appears here
				ePosition = {x: x * fieldSize, y: y * fieldSize};
				var tile = hxd.Res.haxeLogo.toTile();
				eImage = new Bitmap(tile, s2d);
				eImage.setPosition(ePosition.x, ePosition.y - 40);
				eImage.visible = false;
			default:
				// Decorative map markers (A, C, ...) - rendered as text, no logic.
		}
	}

	public function update(dt:Float) {
		// Grid movement while a direction is held (0.1s steps).
		dtCounter += dt;
		if (dtCounter > 0.1) {
			var dirX = input.directionX();
			var dirY = input.directionY();
			if (dirX != 0 || dirY != 0)
				moveIfPositionIsWallFree(player, player.x + dirX * fieldSize, player.y + dirY * fieldSize);
			dtCounter -= 0.1;
		}

		// Show the artifact when the player reaches the exit marker.
		if (ePosition != null && eImage != null)
			eImage.visible = (player.x == ePosition.x && player.y == ePosition.y);

		// Spin the artifact while visible.
		if (eImage != null && eImage.visible)
			eImage.rotation += dt * 2;
	}

	function moveIfPositionIsWallFree(obj:h2d.Object, x:Float, y:Float) {
		if (checkIfPositionIsWallFree(x, y))
			obj.setPosition(x, y);
	}

	function checkIfPositionIsWallFree(x:Float, y:Float):Bool {
		for (w in walls)
			if (w.x == x && w.y == y)
				return false;
		return true;
	}
}
