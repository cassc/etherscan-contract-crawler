// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "../interfaces/IMetadataProvider.sol";

/// @title MentalHealthCoalition
/// ERC-1155 contract that support The Mental Health Coalition
abstract contract MentalHealthCoalition is ERC1155Supply, IAccessControl, ReentrancyGuard {

	/// Defines the Minter/Burner role
	bytes32 public constant MINTER_BURNER_ROLE = keccak256("MINTER_BURNER_ROLE");

	/// Indicates that a token id is not currently valid
	/// @dev Future IMetaDataProvider's may support new token ids
	/// @param tokenId The token that was found to be invalid
	error InvalidTokenId(uint256 tokenId);

	/// Indicates that an invalid IMetadataProvider was supplied
	/// @dev Most likely indicates that the supplied IERC165 contract does not respond that it supports IMetadataProvider
	error InvalidProvider();

	/// Indicates that an attempt to remove a token's IMetadataProvider is not acceptable
	/// @dev Once a given token id is minted its IMetadataProvider cannot be removed, only replaced
	error InvalidStateRequest();

	/// Mints and burns according to the calling Mint/Burner role
	/// @dev Supports a wide variety of minting policies and allows for future innovation
	/// @param owner The owner of the minted or burned tokens
	/// @param mintTokenIds The token ids that will be minted
	/// @param mintTokenAmounts The amounts of tokens to be minted, mapped 1:1 to `mintTokenIds`
	/// @param burnTokenIds The token ids that will be burned
	/// @param burnTokenAmounts The amounts of tokens to be burned, mapped 1:1 to `burnTokenIds`
	function mintBurnBatch(address owner, uint256[] calldata mintTokenIds, uint256[] calldata mintTokenAmounts, uint256[] calldata burnTokenIds, uint256[] calldata burnTokenAmounts) external virtual;

	/// Sets or updates the contract responsible for providing the token's metadata
	/// @dev If no tokens have been minted, it is possible to delete the provider by passing in a 0 address
	/// @param tokenId The token id to modify
	/// @param provider The IMetadataProvider responsible for returning the token's metadata
	function setTokenProvider(uint256 tokenId, address provider) external virtual;
}