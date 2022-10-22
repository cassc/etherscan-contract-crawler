// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IERC1155MetadataURIFormatter
 * @author Limit Break, Inc.
 * @notice Interface for contracts that output ERC-1155 Metadata URIs
 * @dev May be used to return URIs that point off-chain, or may be used to generate URIs/metadata/image on-chain.
 */
interface IERC1155MetadataURIFormatter is IERC165 {

    /// @dev Either returns an off-chain URI or generate metadata and images on-chain.
    function uri() external view returns (string memory);
}