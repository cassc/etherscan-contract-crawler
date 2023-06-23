// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCutFacet {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        bytes4[] functionSelectors;
        address facetAddress;
        FacetCutAction action;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param cut Contains the facet addresses and function selectors
    /// @param init The address of the contract or facet to execute calldata
    /// @param data A function call, including function selector and arguments
    ///                  calldata is executed with delegatecall on init
    function diamondCut(
        FacetCut[] calldata cut,
        address init,
        bytes calldata data
    ) external;

    event DiamondCut(FacetCut[] diamondCut, address init, bytes data);
}