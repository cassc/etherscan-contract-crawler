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
/// @title Endless Crawler Query Utility Interface
/// @author Studio Avante
//
pragma solidity ^0.8.16;
import { ICrawlerToken } from './ICrawlerToken.sol';
import { ICardsMinter } from './external/ICardsMinter.sol';
import { ICardsStore } from './external/ICardsStore.sol';

interface ICrawlerQuery {
	function getChambersContract() external view returns (ICrawlerToken);
	function getCardsContract() external view returns (ICardsMinter);
	function getStoreContract() external view returns (ICardsStore);
	function getOwnedChambers(address account) external view returns (uint256[] memory result);
	function getOwnedCards(address account, uint8 cardType) external view returns (uint256[] memory result);
	function isOwner(address tokenContract, uint256 id, address account) external view returns (bool);
	function getURI(address tokenContract, uint256 id) external view returns (string memory);
}