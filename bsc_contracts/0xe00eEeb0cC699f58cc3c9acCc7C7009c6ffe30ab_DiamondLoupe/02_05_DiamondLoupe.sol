// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./DiamondStorage.sol";
import "./IDiamondLoupe.sol";

// The functions in DiamondLoupe MUST be added to a diamond.
// The EIP-2535 Diamond standard requires these functions.

/**
 * @title Diamond - Loupe
 * @notice Standard EIP-2535 loupe functions to allow inspecting a diamond for explorers.
 *
 * @custom:type eip-2535-facet
 * @custom:category Diamonds
 * @custom:provides-interfaces IDiamondLoupe
 */
contract DiamondLoupe is IDiamondLoupe {
    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns (Facet[] memory facets_) {
        DiamondStorage.Layout storage l = DiamondStorage.layout();
        uint256 numFacets = l.facetAddresses.length;
        facets_ = new Facet[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            address facetAddress_ = l.facetAddresses[i];
            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = l.facetFunctionSelectors[facetAddress_].functionSelectors;
        }
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        DiamondStorage.Layout storage l = DiamondStorage.layout();
        facetFunctionSelectors_ = l.facetFunctionSelectors[_facet].functionSelectors;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        DiamondStorage.Layout storage l = DiamondStorage.layout();
        facetAddresses_ = l.facetAddresses;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        DiamondStorage.Layout storage l = DiamondStorage.layout();
        facetAddress_ = l.selectorToFacetAndPosition[_functionSelector].facetAddress;
    }
}