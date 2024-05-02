.PHONY: run

run:
	zig build -freference-trace
	startx ./xinitrc -- $(shell which Xephyr) :2 -softCursor -br -ac -reset -screen 1600x900 :2
