extends Control

const DARK_BG_LUM = 0.5;

func update_tile(tier: String, color: Color):
	$TileBG.color = color
	$TileBG/TileText.text = tier
	var luminance = color.get_luminance()
	if(luminance < DARK_BG_LUM):
		$TileBG/TileText.set("theme_override_colors/font_color", Color.WHITE)
