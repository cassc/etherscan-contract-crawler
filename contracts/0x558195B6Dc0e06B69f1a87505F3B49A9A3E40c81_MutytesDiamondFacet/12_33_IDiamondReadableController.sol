// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial DiamondReadable interface required by controller functions
 */
interface IDiamondReadableController {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }
}