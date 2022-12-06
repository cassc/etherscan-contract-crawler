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
/// @title Endless Crawler Chamber Renderer Interface
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import { ICrawlerMapper } from './ICrawlerMapper.sol';
import { Crawl } from './Crawl.sol';

interface ICrawlerRenderer is IERC165 {
	function renderAdditionalChamberMetadata(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) external view returns (string memory);
	function renderMapMetadata(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) external view returns (string memory);
	function renderTokenMetadata(Crawl.ChamberData memory chamber, ICrawlerMapper mapper) external view returns (string memory);
}