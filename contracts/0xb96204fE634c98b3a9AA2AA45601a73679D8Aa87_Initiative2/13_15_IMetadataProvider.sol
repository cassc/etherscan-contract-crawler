// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title Provides the metadata for an individual ERC-1155 token
/// @dev Supports the ERC-1155 contract
interface IMetadataProvider is IERC165 {

	/// Returns the encoded metadata
	/// @dev The implementation may choose to ignore the provided tokenId
	/// @param tokenId The ERC-1155 id of the token
	/// @return The raw string to be returned by the uri() function
	function metadata(uint256 tokenId) external view returns (string memory);
}