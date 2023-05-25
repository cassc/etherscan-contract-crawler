// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct AttributeSelection {
	string name;
	string description;
	string dataUri;
}

struct AttributeType {
	string name;
	string description;
	uint8 zIndex;
	bool visible;
	mapping(uint8 => AttributeSelection) selections;
}