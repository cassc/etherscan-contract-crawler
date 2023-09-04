// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IDiamond {
    enum FacetCutAction {
        Add,     // 0
        Replace, // 1
        Remove   // 2
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    struct DiamondArgs {
        address owner;
        address init;
        bytes initCalldata;
    }
}