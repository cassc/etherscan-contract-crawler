// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondReadableController } from "./IDiamondReadableController.sol";

/**
 * @title DiamondReadable interface
 * @dev See https://eips.ethereum.org/EIPS/eip-2535
 */
interface IDiamondReadable is IDiamondReadableController {
    /**
     * @notice Get all of the diamond facets
     * @return facets The facet addresses and their function selectors
     */
    function facets() external returns (Facet[] memory);

    /**
     * @notice Get the function selectors of a facet
     * @param facet The facet address
     * @return selectors The function selectors
     */
    function facetFunctionSelectors(address facet) external returns (bytes4[] memory);

    /**
     * @notice Get all of the diamond's facet addresses
     * @return facetAddresses The facet addresses
     */
    function facetAddresses() external returns (address[] memory);

    /**
     * @notice Get the facet that implements a selector
     * @param selector The function selector
     * @return facetAddress The facet address
     */
    function facetAddress(bytes4 selector) external returns (address);
}