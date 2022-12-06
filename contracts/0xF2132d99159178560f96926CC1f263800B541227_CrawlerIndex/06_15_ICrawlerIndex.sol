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
/// @title Endless Crawler Chapter Index Interface
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { ICrawlerChamberGenerator } from './ICrawlerChamberGenerator.sol';
import { ICrawlerGenerator } from './ICrawlerGenerator.sol';
import { ICrawlerMapper } from './ICrawlerMapper.sol';
import { ICrawlerRenderer } from './ICrawlerRenderer.sol';
import { Crawl } from './Crawl.sol';

interface ICrawlerIndex {
	struct Chapter {
		uint8 chapterNumber;
		ICrawlerGenerator generator;
		ICrawlerMapper mapper;
		ICrawlerRenderer renderer;
	}
	// Public
	function getCurrentChapterNumber() external view returns (uint8);
	function getCurrentChapter() external view returns (Chapter memory);
	function getChapter(uint8 chapterNumber) external view returns (Chapter memory);
	function getChamberGenerator() external view returns (ICrawlerChamberGenerator);
	function getGenerator(uint8 chapterNumber) external view returns (ICrawlerGenerator);
	function getMapper(uint8 chapterNumber) external view returns (ICrawlerMapper);
	function getRenderer(uint8 chapterNumber) external view returns (ICrawlerRenderer);
	// Metadata calls
	function getChamberData(uint8 chapterNumber, uint256 coord, Crawl.ChamberSeed memory chamberSeed, bool generateMaps) external view returns (Crawl.ChamberData memory);
	function getChamberMetadata(uint8 chapterNumber, uint256 coord, Crawl.ChamberSeed memory chamberSeed) external view returns (string memory);
	function getMapMetadata(uint8 chapterNumber, uint256 coord, Crawl.ChamberSeed memory chamberSeed) external view returns (string memory);
	function getTokenMetadata(uint8 chapterNumber, uint256 coord, Crawl.ChamberSeed memory chamberSeed) external view returns (string memory);
}