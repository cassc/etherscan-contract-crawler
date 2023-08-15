//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @title ITPLRevealedParts
/// @author CyberBrokers
/// @author dev by @dievardump
/// @notice Interface for the Revealed Parts contract.
interface ITPLRevealedParts {
	/// @notice Transfers the ownership of multiple NFTs from one address to another address
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenIds The NFTs to transfer
	function batchTransferFrom(address _from, address _to, uint256[] calldata _tokenIds) external;
}