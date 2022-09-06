// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IERC1155MetadataURI {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}