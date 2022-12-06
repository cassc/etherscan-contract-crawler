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
/// @title Endless Crawler Chamber Mapper Interface
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import { Crawl } from './Crawl.sol';

interface ICrawlerMapper is IERC165 {
	// for generators
	function generateTileMap(Crawl.ChamberData memory chamber) external view returns (bytes memory);
	// getters / for renderers
	function getTerrainName(Crawl.Terrain terrain) external view returns (string memory);
	function getGemName(Crawl.Gem gem) external view returns (string memory);
	function getTileName(bytes1 tile, uint8 bitPos) external view returns (string memory);
	function getColors(Crawl.Terrain terrain) external view returns (string[] memory);
	function getColor(Crawl.Terrain terrain, uint8 colorId) external view returns (string memory);
	function getGemColors() external view returns (string[] memory);
	function getGemColor(Crawl.Gem gemType) external view returns (string memory);
	// for renderers
	function getAttributes(Crawl.ChamberData memory chamber) external view returns (string[] memory, string[] memory);
	function renderSvgStyles(Crawl.ChamberData memory chamber) external view returns (string memory);
	function renderSvgDefs(Crawl.ChamberData memory chamber) external view returns (string memory);
}