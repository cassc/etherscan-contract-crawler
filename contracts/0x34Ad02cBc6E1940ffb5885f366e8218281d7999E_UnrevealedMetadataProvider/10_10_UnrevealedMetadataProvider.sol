// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MetadataProvider.sol";

/// @title The All Together Series Unrevealed IMetadataProvider
contract UnrevealedMetadataProvider is MetadataProvider {

	/// @dev Constructs a new instance passing in the IERC1155 token contract
	/// @param tokenContract The IERC1155 that this MetadataProvider will support
	// solhint-disable-next-line no-empty-blocks
	constructor(address tokenContract) MetadataProvider(tokenContract) { }

	/// @dev returns the raw json metadata for the specified token
	/// @param tokenId the id of the requested token
	/// @return The bytes stream of the json metadata
	function contents(uint256 tokenId) internal override pure returns (bytes memory) {
		// Tiers should be 1-4
		if (tokenId >= 8 && tokenId < 12) {
			return abi.encodePacked("{\"name\":\"", "The \\\"All Together\\\" Series", "\",\"image\":\"ipfs://QmUBbyRs1TcvVx7TYJy7wep2PRs5PvX8yEj8vguJ6ahqH8\"}");
		}
		revert UnsupportedTokenId();
	}
}