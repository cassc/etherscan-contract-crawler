// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "./IDiamondCut.sol";
import "./DiamondStorage.sol";
import "../access/ownable/OwnableInternal.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

/**
 * @title Diamond - Cut
 * @notice Standard EIP-2535 cut functionality to add, replace and remove facets from a diamond.
 *
 * @custom:type eip-2535-facet
 * @custom:category Diamonds
 * @custom:provides-interfaces IDiamondCut
 */
contract DiamondCut is IDiamondCut, OwnableInternal {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override onlyOwner {
        DiamondStorage.diamondCut(_diamondCut, _init, _calldata);
    }
}