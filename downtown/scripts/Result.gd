extends RefCounted

## Result<T> - Type-safe error handling
##
## A Result type that can contain either a successful value or an error.
## Inspired by Rust's Result<T, E> pattern.
##
## Usage:
##   var result = Result.ok("success data")
##   if result.success:
##       print("Got: ", result.data)
##   else:
##       print("Error: ", result.error)
##
##   var error_result = Result.create_error("Something went wrong")
##   if not error_result.success:
##       handle_error(error_result.error)

class_name Result

# Result state
var success: bool = false
var data = null
var error: String = ""

func _init() -> void:
	pass

static func ok(data = null) -> Result:
	"""Create a successful result"""
	var result = Result.new()
	result.success = true
	result.data = data
	return result

static func create_error(error_message: String) -> Result:
	"""Create an error result"""
	var result = Result.new()
	result.success = false
	result.error = error_message
	return result

func is_ok() -> bool:
	"""Check if result is successful"""
	return success

func is_error() -> bool:
	"""Check if result contains an error"""
	return not success

func unwrap() -> Variant:
	"""Get the data, panicking if there's an error"""
	if not success:
		push_error("[Result] Attempted to unwrap error result: ", error)
		return null
	return data

func unwrap_or(default: Variant) -> Variant:
	"""Get the data or return default if error"""
	return data if success else default

func expect(error_message: String) -> Variant:
	"""Get the data or push custom error message"""
	if not success:
		push_error("[Result] ", error_message, " - Original error: ", error)
		return null
	return data

func map(transform_func: Callable) -> Result:
	"""Transform the data using a function, if successful"""
	if success:
		return Result.ok(transform_func.call(data))
	return self

func map_error(transform_func: Callable) -> Result:
	"""Transform the error using a function, if failed"""
	if not success:
		return Result.create_error(transform_func.call(error))
	return self

func and_then(chain_func: Callable) -> Result:
	"""Chain operations that return Results"""
	if success:
		return chain_func.call(data)
	return self

func or_else(fallback_func: Callable) -> Result:
	"""Handle errors with a fallback function"""
	if not success:
		return fallback_func.call(error)
	return self

func _to_string() -> String:
	"""String representation for debugging"""
	if success:
		return "[Result:OK] " + str(data)
	else:
		return "[Result:ERROR] " + error