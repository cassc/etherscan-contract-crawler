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
/// @title Endless Crawler IERC721Enumerable implementation Interface
/// @author Studio Avante
//
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IERC721Enumerable is IERC721 {
	function totalSupply() external view returns (uint256);
	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
	function tokenByIndex(uint256 index) external view returns (uint256);
}