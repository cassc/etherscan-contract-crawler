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
/// @title Endless Crawler Player Manager Interface
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { Crawl } from './Crawl.sol';

interface ICrawlerPlayer {
	function transferChamberHoard(address from, address to, Crawl.Hoard memory hoard) external;
}