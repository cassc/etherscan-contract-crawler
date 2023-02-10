//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IVerified
/// @author @dievardump
interface IVerified {
	/// @notice Returns a `tokenId` extra data
	/// @param tokenId the toke id
	/// @return the extraData

	function extraData(uint256 tokenId) external view returns (uint256);

	/// @notice allows a minter to mint a token to `to` with `extraData`
	function mint(address to, uint24 extraData) external returns (uint256);

	/// @notice allows a token owner OR a minter to set the extra data for a token (here the index of dataHolder)
	function setExtraData(uint256 tokenId, uint24 index) external;
}