// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Partial Rights Protocol Smart Contract interface
 */
interface IRightsProtocol {
	/**
	 * @dev Returns a list of Rights URIs (Uniform Resource Identifiers) for token `tokenID` of contract `contractAddr`.
	 *      This function should be called by the NFT contracts
	 */
	function rightsURIs(address contractAddr, uint256 tokenID) external view returns (string[] memory);
}