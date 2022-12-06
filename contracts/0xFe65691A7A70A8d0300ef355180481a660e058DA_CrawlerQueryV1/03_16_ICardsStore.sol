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
/// @title Cards Store interface
/// @author Studio Avante
/// @notice Cards Store interface
/// @dev Serves CardsMinter.sol
pragma solidity ^0.8.16;

interface ICardsStore {
	function getVersion() external view returns (uint8);
	function exists(uint256 id) external view returns (bool);
	function getCardCount() external view returns (uint256);
	function getCardSupply(uint256 id) external view returns (uint256);
	function getCardPrice(uint256 id) external view returns (uint256);
	function beforeMint(uint256 id, uint256 currentSupply, uint256 balance, uint256 value) external view;
	function uri(uint256 id) external view returns (string memory);
}