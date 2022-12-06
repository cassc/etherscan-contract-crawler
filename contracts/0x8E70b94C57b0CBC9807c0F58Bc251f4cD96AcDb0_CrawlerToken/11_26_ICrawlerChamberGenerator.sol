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
/// @title Endless Crawler Static Chamber Generator Interface (static data)
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { ICrawlerGenerator } from './ICrawlerGenerator.sol';
import { ICrawlerToken } from './ICrawlerToken.sol';
import { Crawl } from './Crawl.sol';

interface ICrawlerChamberGenerator {
	function generateTerrainType(uint256 seed, Crawl.Terrain fromTerrain) external view returns (Crawl.Terrain);
	function generateHoard(uint256 seed) external view returns (Crawl.Hoard memory);
	function generateChamberData(uint256 coord, Crawl.ChamberSeed memory chamberSeed, bool generateMaps, ICrawlerToken tokenContract, ICrawlerGenerator customGenerator) external view returns (Crawl.ChamberData memory);
}