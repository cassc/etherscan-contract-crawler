// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
pragma experimental ABIEncoderV2;

interface IDiamondCutCommon {
    enum FacetCutAction {
        ADD,
        REPLACE,
        REMOVE
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facet;
        FacetCutAction action;
        bytes4[] selectors;
    }

    struct Initialization {
        address target;
        bytes data;
    }

    /// @notice Emitted when at least a cut action is operated on the diamond.
    /// @param cuts The list of facet addresses, actions and function selectors applied to the diamond.
    /// @param target The address of the contract where `data` was executed.
    /// @param data The encoded function call executed on `target`.
    event DiamondCut(FacetCut[] cuts, address target, bytes data);
}