// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * Metadata for lazy delivery tokens
 */
interface ILazyDeliveryMetadata is IERC165 {

    function assetURI(uint256 assetId) external view returns(string memory);

}