// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IRootCollectionInitializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to be tied to a root ERC-721 collection.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IRootCollectionInitializer is IERC165 {

    /**
     * @notice Initializes root collection parameters
     */
    function initializeRootCollections(address[] memory rootCollection_, uint256[] memory rootCollectionMaxSupply_, uint256[] memory tokensPerClaim_) external;
}