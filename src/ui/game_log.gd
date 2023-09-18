extends RichTextLabel

@export var MAX_LINES : int = 100

func log_text(_text : String):
	append_text("\n> %s" % _text)
	var count = get_paragraph_count()
	if(count > MAX_LINES):
		for i in count - MAX_LINES:
			remove_paragraph(0)

func _ready():
	if get_parent() != get_tree().root: return
	
	for i in 100:
		log_text("\nLine %d-0\nBAAAH\nMOOOO" % i)
		await get_tree().create_timer(0.1).timeout
