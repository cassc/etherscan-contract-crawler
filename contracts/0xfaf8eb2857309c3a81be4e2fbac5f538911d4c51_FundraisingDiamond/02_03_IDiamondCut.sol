// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    Diamond cut interface

    ------------------------------

    @author Nick Mudge

 **************************************/

interface IDiamondCut {
    // enum
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    // struct
    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    // event
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    /**************************************

        Cut diamond

        ------------------------------

        @notice Add/replace/remove any number of functions and optionally execute a function with delegatecall
        @param _diamondCut Contains the facet addresses and function selectors
        @param _init The address of the contract or facet to execute _calldata
        @param _calldata A function call, including function selector and arguments, that is executed with delegatecall on _init

     **************************************/

    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}