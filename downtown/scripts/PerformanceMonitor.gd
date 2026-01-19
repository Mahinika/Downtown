extends Node

## PerformanceMonitor - Automated performance monitoring and logging system
##
## Singleton Autoload that tracks performance metrics including FPS, memory usage,
## and system performance. Provides automated alerting and logging capabilities.
##
## Key Features:
## - Real-time FPS monitoring with alerts
## - Memory usage tracking per system
## - Performance benchmarking for operations
## - Automated logging and reporting
## - Configurable thresholds and alerts
##
## Usage:
##   PerformanceMonitor.start_monitoring()
##   PerformanceMonitor.log_fps()
##   PerformanceMonitor.check_performance_thresholds()

## Emitted when performance threshold is exceeded
signal performance_alert(metric: String, value: float, threshold: float)

## Emitted when performance benchmark completes
signal benchmark_complete(operation: String, time_taken: float)

## Current FPS value
var current_fps: float = 0.0

## FPS history for averaging (last 60 frames)
var fps_history: Array[float] = []

## Memory usage tracking
var memory_usage: Dictionary = {}

## Performance thresholds
var fps_threshold: float = 30.0  # Minimum acceptable FPS
var memory_threshold: float = 400.0  # MB - Maximum acceptable memory usage
var frame_time_threshold: float = 33.3  # ms - Maximum acceptable frame time (30 FPS)

## Performance monitoring settings
var monitoring_enabled: bool = true
var log_interval: float = 5.0  # Log every 5 seconds
var alert_cooldown: float = 10.0  # Minimum time between alerts
var history_size: int = 60  # Keep 60 frames of history

## Internal timers
var _log_timer: float = 0.0
var _alert_timer: float = 0.0

## Benchmark tracking
var active_benchmarks: Dictionary = {}

func _ready() -> void:
	print("[PerformanceMonitor] Initialized - Automated performance monitoring active")
	if monitoring_enabled:
		start_monitoring()

func _process(delta: float) -> void:
	if not monitoring_enabled:
		return

	# Update FPS tracking
	_update_fps_tracking()

	# Periodic logging
	_log_timer += delta
	if _log_timer >= log_interval:
		_log_timer = 0.0
		_log_performance_metrics()

	# Alert cooldown
	_alert_timer += delta

func start_monitoring() -> void:
	"""Start automated performance monitoring"""
	monitoring_enabled = true
	print("[PerformanceMonitor] Started automated performance monitoring")
	print("[PerformanceMonitor] FPS threshold: %.1f" % fps_threshold)
	print("[PerformanceMonitor] Memory threshold: %.1f MB" % memory_threshold)

func stop_monitoring() -> void:
	"""Stop performance monitoring"""
	monitoring_enabled = false
	print("[PerformanceMonitor] Stopped performance monitoring")

func _update_fps_tracking() -> void:
	"""Update FPS tracking and history"""
	current_fps = Performance.get_monitor(Performance.TIME_FPS)

	# Maintain FPS history
	fps_history.append(current_fps)
	if fps_history.size() > history_size:
		fps_history.remove_at(0)

func _log_performance_metrics() -> void:
	"""Log current performance metrics"""
	if not monitoring_enabled:
		return

	var avg_fps = _calculate_average_fps()
	var memory_mb = _get_memory_usage_mb()

	# Log to console (could be extended to file logging)
	print("[PerformanceMonitor] FPS: %.1f (avg: %.1f) | Memory: %.1f MB" % [current_fps, avg_fps, memory_mb])

	# Check performance thresholds
	_check_performance_thresholds(avg_fps, memory_mb)

func _calculate_average_fps() -> float:
	"""Calculate average FPS from history"""
	if fps_history.is_empty():
		return current_fps

	var sum = 0.0
	for fps in fps_history:
		sum += fps
	return sum / fps_history.size()

func _get_memory_usage_mb() -> float:
	"""Get current memory usage in MB"""
	# Use static memory as primary indicator, with fallback
	var memory_mb = 0.0

	# Get static memory usage (most reliable indicator)
	memory_mb = Performance.get_monitor(Performance.MEMORY_STATIC)

	# If static memory is not available, use a reasonable default
	if memory_mb <= 0.0:
		memory_mb = 50.0 * 1024.0 * 1024.0  # 50MB default estimate

	return memory_mb / (1024.0 * 1024.0)  # Convert to MB

func _check_performance_thresholds(avg_fps: float, memory_mb: float) -> void:
	"""Check if performance metrics exceed thresholds and emit alerts"""
	if _alert_timer < alert_cooldown:
		return

	var alert_triggered = false

	# FPS threshold check
	if avg_fps < fps_threshold:
		performance_alert.emit("fps", avg_fps, fps_threshold)
		print("[PerformanceMonitor] ⚠️ ALERT: Low FPS detected (%.1f < %.1f)" % [avg_fps, fps_threshold])
		alert_triggered = true

	# Memory threshold check
	if memory_mb > memory_threshold:
		performance_alert.emit("memory", memory_mb, memory_threshold)
		print("[PerformanceMonitor] ⚠️ ALERT: High memory usage detected (%.1f MB > %.1f MB)" % [memory_mb, memory_threshold])
		alert_triggered = true

	# Frame time check (rough estimate)
	var frame_time = 1000.0 / current_fps  # ms per frame
	if frame_time > frame_time_threshold:
		performance_alert.emit("frame_time", frame_time, frame_time_threshold)
		print("[PerformanceMonitor] ⚠️ ALERT: Slow frame time detected (%.1f ms > %.1f ms)" % [frame_time, frame_time_threshold])
		alert_triggered = true

	if alert_triggered:
		_alert_timer = 0.0

func start_benchmark(operation_name: String) -> void:
	"""Start timing a performance benchmark"""
	if not monitoring_enabled:
		return

	var start_time = Time.get_ticks_usec()
	active_benchmarks[operation_name] = start_time
	print("[PerformanceMonitor] Started benchmark: %s" % operation_name)

func end_benchmark(operation_name: String) -> float:
	"""End timing a performance benchmark and return elapsed time"""
	if not active_benchmarks.has(operation_name):
		print("[PerformanceMonitor] Warning: Benchmark '%s' was not started" % operation_name)
		return 0.0

	var start_time = active_benchmarks[operation_name]
	var end_time = Time.get_ticks_usec()
	var elapsed_usec = end_time - start_time
	var elapsed_ms = elapsed_usec / 1000.0

	active_benchmarks.erase(operation_name)
	benchmark_complete.emit(operation_name, elapsed_ms)
	print("[PerformanceMonitor] Benchmark completed: %s - %.2f ms" % [operation_name, elapsed_ms])

	return elapsed_ms

func get_performance_report() -> Dictionary:
	"""Get comprehensive performance report"""
	return {
		"fps": {
			"current": current_fps,
			"average": _calculate_average_fps(),
			"threshold": fps_threshold
		},
		"memory": {
			"current_mb": _get_memory_usage_mb(),
			"threshold_mb": memory_threshold
		},
		"frame_time": {
			"current_ms": 1000.0 / current_fps,
			"threshold_ms": frame_time_threshold
		},
		"active_benchmarks": active_benchmarks.size(),
		"monitoring_enabled": monitoring_enabled
	}

func set_fps_threshold(threshold: float) -> void:
	"""Set the minimum acceptable FPS threshold"""
	fps_threshold = threshold
	print("[PerformanceMonitor] FPS threshold set to: %.1f" % threshold)

func set_memory_threshold(threshold_mb: float) -> void:
	"""Set the maximum acceptable memory usage threshold"""
	memory_threshold = threshold_mb
	print("[PerformanceMonitor] Memory threshold set to: %.1f MB" % threshold_mb)

func reset_history() -> void:
	"""Reset performance history"""
	fps_history.clear()
	print("[PerformanceMonitor] Performance history reset")

# Debug functions for manual testing
func force_performance_alert() -> void:
	"""Force a performance alert for testing (debug only)"""
	performance_alert.emit("debug", 0.0, 0.0)
	print("[PerformanceMonitor] Debug alert triggered")

func log_detailed_performance() -> void:
	"""Log detailed performance metrics"""
	var report = get_performance_report()
	print("[PerformanceMonitor] Detailed Performance Report:")
	print("  FPS: %.1f (avg: %.1f, threshold: %.1f)" % [report.fps.current, report.fps.average, report.fps.threshold])
	print("  Memory: %.1f MB (threshold: %.1f MB)" % [report.memory.current_mb, report.memory.threshold_mb])
	print("  Frame Time: %.1f ms (threshold: %.1f ms)" % [report.frame_time.current_ms, report.frame_time.threshold_ms])
	print("  Active Benchmarks: %d" % report.active_benchmarks)
