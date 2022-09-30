// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {LibDiamond} from "../libs/LibDiamond.sol";
import {IDiamondLoupeFacet} from "../interfaces/IDiamondLoupeFacet.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract DiamondLoupeFacet is IDiamondLoupeFacet, IERC165 {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.

    /// @inheritdoc IDiamondLoupeFacet
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numFacets = ds.facetAddresses.length;
        facets_ = new Facet[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            address facetAddr = ds.facetAddresses[i];
            facets_[i].facetAddress = facetAddr;
            facets_[i].functionSelectors = ds
                .facetFunctionSelectors[facetAddr]
                .functionSelectors;
        }
    }

    /// @inheritdoc IDiamondLoupeFacet
    function facetFunctionSelectors(address facet)
        external
        view
        override
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetFunctionSelectors_ = ds
            .facetFunctionSelectors[facet]
            .functionSelectors;
    }

    /// @inheritdoc IDiamondLoupeFacet
    function facetAddresses()
        external
        view
        override
        returns (address[] memory facetAddresses_)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddresses_ = ds.facetAddresses;
    }

    /// @inheritdoc IDiamondLoupeFacet
    function facetAddress(bytes4 functionSelector)
        external
        view
        override
        returns (address facetAddress_)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds
            .selectorToFacetAndPosition[functionSelector]
            .facetAddress;
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 interfaceId)
        external
        view
        override
        returns (bool)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[interfaceId];
    }
}