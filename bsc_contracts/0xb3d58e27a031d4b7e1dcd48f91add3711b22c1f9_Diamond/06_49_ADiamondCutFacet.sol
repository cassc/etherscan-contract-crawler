// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "./IDiamondCut.sol";
import {LibDiamond} from "./LibDiamond.sol";
import {FacetCut} from "./Facet.sol";

abstract contract ADiamondCutFacet is IDiamondCut {
  // override this function to change the admin role
  modifier onlyAuthorized() virtual {
    revert();
    _;
  }

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
  ) external override onlyAuthorized {
    LibDiamond.diamondCut(_diamondCut, _init, _calldata);
  }
}