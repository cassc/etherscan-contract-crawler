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
/// @title Endless Crawler Contract Manifest Interface
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { IERC165 } from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface ICrawlerContract is IERC165 {
	function contractName() external view returns (string memory);
	function contractChapterNumber() external view returns (uint8);
	function contractVersion() external view returns (uint8);
}