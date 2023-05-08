// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "@lib-diamond/src/diamond/IDiamondCut.sol";
import {LibDiamond} from "@lib-diamond/src/diamond/LibDiamond.sol";
import {FacetCut, Facet} from "@lib-diamond/src/diamond/Facet.sol";
import {DiamondStorage} from "@lib-diamond/src/diamond/DiamondStorage.sol";
import {DiamondLoupeFacet} from "@lib-diamond/src/diamond/DiamondLoupeFacet.sol";

import {WithRoles} from "@lib-diamond/src/access/access-control/WithRoles.sol";
import {DEFAULT_ADMIN_ROLE} from "@lib-diamond/src/access/access-control/Roles.sol";

contract DiamondCutAndLoupeFacet is DiamondLoupeFacet, IDiamondCut, WithRoles {
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
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    LibDiamond.diamondCut(_diamondCut, _init, _calldata);
  }
}