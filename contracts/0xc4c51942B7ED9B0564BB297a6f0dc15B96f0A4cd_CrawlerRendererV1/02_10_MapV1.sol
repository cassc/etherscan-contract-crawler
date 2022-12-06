// SPDX-License-Identifier: MIT
//
//    ██████████
//   █          █
//  █            █
//  █            █
//  █            █
//  █    ░░░░    █
//  █   ▓▓▓▓▓▓   █
//  █  ████████  █
//
// https://endlesscrawler.io
// @EndlessCrawler
//
/// @title Endless Crawler Mapper Constants v.1
/// @author Studio Avante
/// @dev Definitions and functions for Mappers and Renderers
//
pragma solidity ^0.8.16;

library MapV1 {
	uint8 internal constant Color_Background = 0;
	uint8 internal constant Color_Path = 1;
	uint8 internal constant Color_Tiles = 2;
	uint8 internal constant Color_Shadows = 3;
	uint8 internal constant Color_Player = 4;
	bytes1 internal constant Tile_Void = 0x00;
	bytes1 internal constant Tile_Entry = 0x01;
	bytes1 internal constant Tile_Exit = 0x02;
	bytes1 internal constant Tile_LockedExit = 0x03;
	bytes1 internal constant Tile_Gem = 0x04;
	bytes1 internal constant Tile_Empty = 0xfe;
	bytes1 internal constant Tile_Path = 0xff;
}