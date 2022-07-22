// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial DiamondWritable interface required by controller functions
 */
interface IDiamondWritableController {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    error UnexpectedFacetCutAction(FacetCutAction action);

    event DiamondCut(FacetCut[] diamondCut, address init, bytes data);
}