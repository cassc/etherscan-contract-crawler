// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondWritableController } from "./IDiamondWritableController.sol";

/**
 * @title DiamondWritable interface
 * @dev See https://eips.ethereum.org/EIPS/eip-2535
 */
interface IDiamondWritable is IDiamondWritableController {
    /**
     * @notice Add/replace/remove functions
     * @dev Executes a callback function if applicable
     * @param facetCuts The facet addresses and function selectors
     * @param init The callback address
     * @param data The callback function call
     */
    function diamondCut(
        FacetCut[] calldata facetCuts,
        address init,
        bytes calldata data
    ) external;
}