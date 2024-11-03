@tool
@icon("icon.svg")
class_name AGInfiniteScroll2D extends Control


## 在 item 被使用前调用;
## 如果需要可以设置 item.node 属性;
## 比如: 图片使用 Sprite2D包装, 需要可以翻转;
signal before_use_item(item: AGScrollItem, idx: int)


## 滚动的方向
@export var direction := AGScrollManager.Direction.LEFT:
	set(val):
		direction = val
		if val != _manager.direction:
			_manager.direction = direction
			_reset_pool_and_manager()

## 滚动的速度
@export var speed: float = 200.0

## 是否启用滚动
@export var enable := true:
	set(val):
		enable = val
		_reset_pool_and_manager()

## 自定义内容加载器
@export var content_loaders: Array[AGBaseLoader] = []:
	set(val):
		content_loaders = val
		_pool.loaders = val
		_reset_pool_and_manager()

## 随机加载 还是 顺序加载 内容!
@export var content_randomly: bool = false

## 使用中的内容个数, 一般足够滚动切换就行
@export var content_size: int = 3:
	set(val):
		content_size = val
		# 从新加载
		if val != _manager.items.size():
			_reset_pool_and_manager()

## 背景色
@export var background_color: Color:
	set(val):
		background.color = val
	get():
		return background.color

## 滚动位置
var _index: int = -1

## 滚动管理器
var _manager := AGScrollManager.new()
## 加载池
var _pool := AGScrollPool.new()

var background: ColorRect:
	get():
		if not background:
			background = ColorRect.new()
			background.color = Color.REBECCA_PURPLE
			background.set_anchors_preset(Control.PRESET_FULL_RECT)
			add_child(background)
		return background

func _ready() -> void:
	_pool.loaders = content_loaders
	_pool.pre_load_items(content_size, content_randomly)




func _process(delta: float) -> void:
	if not enable and not _manager.items.is_empty():
		return
	
	if _manager.items.is_empty():
		# 初始化当前节点s
		for i in range(content_size):
			var r = false if i == 0 else content_randomly
			var ri = _pool.pop_item(r)
			var si = AGScrollItem.new(ri, size)
			_emit_before_use_item(si)
			_manager.items.append(si)
			if i == 0 and ri.direction != AGScrollManager.Direction.NONE:
				_manager.direction = ri.direction
			background.add_child(si)
	
	# 更新偏移
	var distance = speed * delta
	if not enable:
		distance = 0
	
	# 滚动ing
	var offset = Vector2.ZERO
	if _manager.is_down_or_right():
		var front = _manager.items.front() as AGScrollItem
		if _manager.is_down():
			offset.y = size.y - front.size.y
		elif _manager.is_right():
			offset.x = size.x - front.size.x
	_manager.update_postions(distance, offset)
	
	# 处理, 从父结点上移除或添加
	if not _manager.opt_items.is_empty():
		for item in _manager.opt_items:
			# 需要在视图上的加上去
			item.add_to_if_needed(background)
			# 需要移除的视图移除掉
			item.remove_from_if_needed(background)
		_manager.opt_items.clear()
	
	# 超出屏幕?
	var popItem = _manager.pop_front_if_needed()
	if popItem != null:
		var ri = _pool.pop_item(content_randomly)
		var si = AGScrollItem.new(ri, size)
		_emit_before_use_item(si)
		_manager.items.append(si)
		_manager.reset_offset()
		if ri.direction != AGScrollManager.Direction.NONE:
			_manager.direction = ri.direction
		else:
			_manager.direction = direction
		# 待操作
		popItem.need_remove_from_parent = true
		si.need_add_to_parent = true
		_manager.opt_items.append(popItem)
		_manager.opt_items.append(si)


func _emit_before_use_item(item: AGScrollItem) -> void:
	_index += 1
	if before_use_item.get_connections().size() > 0:
		before_use_item.emit(item, _index)


## 重置缓存池 和 滚动管理者
func _reset_pool_and_manager() -> void:
	for child in background.get_children():
		background.remove_child(child)
	_manager.items.clear()
	_manager.reset_offset()
	_pool.clear_caches()
	_pool.pre_load_items(content_size, content_randomly)
