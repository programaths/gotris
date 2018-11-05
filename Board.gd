extends Node2D

# Now we have to hook real pieces to these signal
# The board can handle the basic "Tetris" logic
# Remains to clear lines
signal block_spawned(block_type,block_data)
signal block_fixed(block_data)
signal block_moved(before,after,block_data)

var cells = {}

var current_block={
	"type" : [],
	"position" : {"r":0,"c":0}
}

var can_move = true

const COLLIDE_LEFT = -1
const COLLIDE_RIGHT = -2
const COLLIDE_PIECE = -3

var i_block = [
	[0,0,1,0],
	[0,0,1,0],
	[0,0,1,0],
	[0,0,1,0],
]
var l_block = [
	[0,0,0,0],
	[0,1,0,0],
	[0,1,0,0],
	[0,1,1,0],
]

var L_block = [
	[0,0,0,0],
	[0,1,1,0],
	[0,1,0,0],
	[0,1,0,0],
]

var n_block = [
	[0,0,0,0],
	[0,0,1,0],
	[0,1,1,0],
	[0,1,0,0]
]

var N_block = [
	[0,0,0,0],
	[0,1,0,0],
	[0,1,1,0],
	[0,0,1,0]
]

var o_block = [
	[0,0,0,0],
	[0,1,1,0],
	[0,1,1,0],
	[0,0,0,0]
]

var t_block = [
	[0,0,0,0],
	[0,0,1,0],
	[0,1,1,1],
	[0,0,0,0]
]

var block_types = [
	i_block,l_block,L_block,n_block,N_block,o_block,t_block
]

func _ready():
	# Board initialisation
	for i in range(16):
		for j in range(8):
			cells[{"r":i,"c":j}] = false
			
func _process(delta):
	if can_move:
		can_move = false
		var move_occured = false
		if Input.is_action_pressed("ui_left"):
			move_occured = move_left()
		if !move_occured and Input.is_action_pressed("ui_right"):
			move_occured = move_right()
		if move_occured:
			yield(get_tree().create_timer(1),"timeout")
		can_move = true

func move_left():
	current_block.position.x = current_block.position.x - 1
	if collide(current_block) == 0:
		emit_signal("block_moved",{"x":current_block.position.x+1,"y":current_block.position.y},{"x":current_block.position.x,"y":current_block.position.y},current_block)
		return true
	current_block.position.x = current_block.position.x + 1
	return false
	
func move_right():
	current_block.position.x = current_block.position.x + 1
	if collide(current_block) == 0:
		emit_signal("block_moved",{"x":current_block.position.x-1,"y":current_block.position.y},{"x":current_block.position.x,"y":current_block.position.y},current_block)
		return true
	current_block.position.x = current_block.position.x - 1
	return false

func new_block():
	pass
	
static func iclamp(n,a,b):
	if n<a:
		return a
	if n>b:
		return b
	return n
	
# Offset top top left
static func top_left(a):
	var top = -1
	var left = -1
	for i in range(a.size()):
		for j in range(a[i].size()):
			if top == -1 and a[i][j]==1:
				top = i
			if a[i][j]==1:
				if left==-1:
					left=j
				else:
					if j<left:
						left=j
	return {"top":top,"left":left}
	
static func bot_right(a):
	var bot = -1
	var right = -1
	for i in range(a.size()):
		for j in range(a[i].size()):
			if a[i][j]==1:
				if bot == -1:
					bot = i
				if right==-1:
					right = j
				if i>bot:
					bot = i
				if j>right:
					right = j
	return {
		"bot": bot,
		"right":right
	}
	
func collide(p):
	var off_top_left = top_left(p.type)
	var off_bot_right = bot_right(p.type)
	if p.position.c + off_top_left.left < 0:
		return COLLIDE_LEFT
	if p.position.c + off_bot_right.right > 8:
		return COLLIDE_RIGHT
	for i in range(off_top_left.top,off_bot_right.bot+1):
		for j in range(off_top_left.left,off_bot_right.right+1):
			var tcell ={"r":p.position.y+i,"c":p.position.x+j} 
			if cells.has(tcell) and cells[tcell]==1:
				return COLLIDE_PIECE
	return 0
	
func spawn_block():
	var block_type=randi()%7
	current_block = {
		"type" : block_types[block_type],
		"position":{"x":6,"y":15}
	}
	emit_signal("block_spawned",block_type,current_block)
	
func rotate_right(p):
	#  Transpose \ + Vertical mirror |
	for i in range(5):
		for j in range(5):
			var tmp = p.type[j][i]
			p.type[j][i]=p.type[i][4-j]
			p.type[i][4-j]=tmp
			
func rotate_left(p):
	# Vertical mirror | + Transpose \
	# Or: Transpose \ + Horizontal mirror -
	for i in range(5):
		for j in range(5):
			var tmp = p.type[j][i]
			p.type[j][i]=p.type[4-i][j]
			p.type[4-i][j]=tmp
	
func fix_block(p):
	var off_top_left = top_left(p.type)
	var off_bot_right = bot_right(p.type)
	for i in range(off_top_left.top,off_bot_right.bot+1):
		for j in range(off_top_left.left,off_bot_right.right+1):
			var tcell ={"r":p.position.y+i,"c":p.position.x+j} 
			if cells.has(tcell):
				cells[tcell]=1
	# Here is a good place to check for lines and push the field down

func _on_BlockDescentTimer_timeout():
	current_block.position.y = current_block.position.y - 1
	if collide(current_block)<0:
		fix_block(current_block)
		emit_signal("block_fixed",current_block)
	
