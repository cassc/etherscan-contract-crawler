// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author dievardump (https://twitter.com/dievardump)
interface IMetadataHelper {
	function tokenURI(
		address creator,
		uint256 tokenId,
		uint32 seriesId,
		uint32 index
	) external view returns (string memory);
}