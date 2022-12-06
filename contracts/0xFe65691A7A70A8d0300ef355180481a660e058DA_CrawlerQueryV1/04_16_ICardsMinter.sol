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
/// @title Endless Crawler Cards Minter Interface
/// @author Studio Avante
/// @dev use this interface for contract interaction
pragma solidity ^0.8.16;
import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

interface ICardsMinter is IERC1155 {

	/// @notice Check if the purchases are paused
	/// @return bool True if paused, False if unpaused
	function isPaused() external view returns (bool);

	/// @notice Returns a Token unit price, not considering availability
	/// @param id Token id
	/// @return price Price of the token, in WEI
	function getPrice(uint256 id) external view returns (uint256);

	/// @notice Run all require tests for a successful purchase()
	/// @param id Token id
	/// @param value Value that will be sent to purchase(), in WEI
	/// @return bool True if purchase is allowed, False if not
	/// @return reason The reason when purchase now allowed
	function canPurchase(uint256 id, uint256 value) external view returns (bool, string memory);
	/// @notice Purchases 1 Token for the Sender. The message value must be equal or higher than getPrice(id)
	/// @param id Token id
	/// @param data Nevermind, use []
  function purchase(uint256 id, bytes memory data) external view;

	/// @notice Burn tokens. Sender must be owner or approved
	/// @param id Token id
	/// @param amount The amount of tokens to burn
	function burn(uint256 id, uint256 amount) external view;

	/// @notice Returns a token metadata, compliant with ERC1155Metadata_URI
	/// @param id Token id
	/// @return metadata Token metadata, as json string base64 encoded
	function uri(uint256 id) external view returns (string memory);

}