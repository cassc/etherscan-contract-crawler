// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {LibDiamond} from "./LibDiamond.sol";
import {DiamondStorage} from "./DiamondStorage.sol";
import {IDiamondLoupe} from "./IDiamondLoupe.sol";

import {Facet} from "./Facet.sol";

contract DiamondLoupeFacet is IDiamondLoupe {
  // Diamond Loupe Functions
  ////////////////////////////////////////////////////////////////////
  /// These functions are expected to be called frequently by tools.
  //
  // struct Facet {
  //     address facetAddress;
  //     bytes4[] functionSelectors;
  // }

  /// @notice Gets all facets and their selectors.
  /// @return facets_ Facet
  function facets() external view override returns (Facet[] memory facets_) {
    DiamondStorage storage ds = LibDiamond.DS();
    uint256 numFacets = ds.facetAddresses.length;
    facets_ = new Facet[](numFacets);
    for (uint256 i = 0; i < numFacets; ) {
      address facetAddress_ = ds.facetAddresses[i];
      facets_[i].facetAddress = facetAddress_;
      facets_[i].functionSelectors = ds.facetFunctionSelectors[facetAddress_].functionSelectors;
      unchecked {
        ++i;
      }
    }
  }

  /// @notice Gets all the function selectors provided by a facet.
  /// @param _facet The facet address.
  /// @return facetFunctionSelectors_
  function facetFunctionSelectors(
    address _facet
  ) external view override returns (bytes4[] memory facetFunctionSelectors_) {
    DiamondStorage storage ds = LibDiamond.DS();
    facetFunctionSelectors_ = ds.facetFunctionSelectors[_facet].functionSelectors;
  }

  /// @notice Get all the facet addresses used by a diamond.
  /// @return facetAddresses_
  function facetAddresses() external view override returns (address[] memory facetAddresses_) {
    DiamondStorage storage ds = LibDiamond.DS();
    facetAddresses_ = ds.facetAddresses;
  }

  /// @notice Gets the facet that supports the given selector.
  /// @dev If facet is not found return address(0).
  /// @param _functionSelector The function selector.
  /// @return facetAddress_ The facet address.
  function facetAddress(
    bytes4 _functionSelector
  ) external view override returns (address facetAddress_) {
    DiamondStorage storage ds = LibDiamond.DS();
    facetAddress_ = ds.selectorToFacetAndPosition[_functionSelector].facetAddress;
  }
}