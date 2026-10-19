.PHONY: build test verify run format

build:
	python3 scripts/build_app.py

test:
	swift test

verify:
	python3 scripts/verify_app.py

run: build
	open dist/Domo.app

format:
	xcrun swift-format format --in-place --recursive Sources Tests Package.swift
