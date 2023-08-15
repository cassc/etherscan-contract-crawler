// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ICyberbrokersAccolades {
	/// @notice Allows minter to mint `amount` token of `tokenId` to each `addresses[index]`
	/// @param addresses the addresses to mint to
	/// @param tokenId the token id to mint
	/// @param amount the amount to mint
	function mint(address[] calldata addresses, uint256 tokenId, uint256 amount) external;

	/// @notice Allows minter to mint `amounts[index]` tokens of `tokenIds[index]` to `addresses[index]`
	/// @param addresses the addresses to mint to
	/// @param tokenIds the token ids to mint
	/// @param amounts the amount for each token ids to mint
	function mintBatch(address[] calldata addresses, uint256[] calldata tokenIds, uint256[] calldata amounts) external;
}