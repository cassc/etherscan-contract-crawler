// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./RoyalNFT.sol";

/**
 * @title Personality Pod, a.k.a. AI Personality
 *
 * @notice Personality Pod replaces AI Pod in version 2 release, it doesn't
 *      store any metadata on-chain, all the token related data except URI
 *      (rarity, traits, etc.) is expected to be stored off-chain
 *
 * @notice Terms Personality Pod and AI Personality have identical meaning and
 *      used interchangeably all over the code, documentation, scripts, etc.
 *
 * @dev Personality Pod is a Tiny ERC721, it supports minting and burning,
 *      its token ID space is limited to 32 bits
 */
contract PersonalityPodERC721 is RoyalNFT {
	/**
	 * @inheritdoc TinyERC721
	 */
	uint256 public constant override TOKEN_UID = 0xd9b5d3b66c60255ffa16c57c0f1b2db387997fa02af673da5767f1acb0f345af;

	/**
	 * @dev Constructs/deploys AI Personality instance
	 *      with the name and symbol defined during the deployment
	 */
	constructor(string memory _name, string memory _symbol) RoyalNFT(_name, _symbol) {}
}