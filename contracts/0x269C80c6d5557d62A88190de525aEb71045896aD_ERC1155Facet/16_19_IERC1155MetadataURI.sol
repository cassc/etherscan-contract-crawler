// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC1155 Multi Token Standard, optional extension: Metadata URI.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0x0e89341c.
interface IERC1155MetadataURI {
    /// @notice Retrieves the URI for a given token.
    /// @dev URIs are defined in RFC 3986.
    /// @dev The URI MUST point to a JSON file that conforms to the "ERC1155 Metadata URI JSON Schema".
    /// @dev The uri function SHOULD be used to retrieve values if no event was emitted.
    /// @dev The uri function MUST return the same value as the latest event for an _id if it was emitted.
    /// @dev The uri function MUST NOT be used to check for the existence of a token as it is possible for
    ///  an implementation to return a valid string even if the token does not exist.
    /// @return metadataURI The URI associated to the token.
    function uri(uint256 id) external view returns (string memory metadataURI);
}