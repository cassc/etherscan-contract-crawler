// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// OpenZeppelin imports
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// Diamond imports
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IDiamondCut } from  "../interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";

/**************************************

    Diamond loupe facet

    ------------------------------

    @author Nick Mudge
    @dev These functions are expected to be called frequently by tools

        struct Facet {
         address facetAddress;
         bytes4[] functionSelectors;
        }

 **************************************/

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {

    /**************************************

        Get facets

        ------------------------------

        @notice Gets all facet addresses and their four byte function selectors
        @return facets_ Facet

     **************************************/

    function facets() external override view returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numFacets = ds.facetAddresses.length;
        facets_ = new Facet[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            address facetAddress_ = ds.facetAddresses[i];
            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = ds.facetFunctionSelectors[facetAddress_].functionSelectors;
        }
    }

    /**************************************

        Get facet function selectors

        ------------------------------

        @notice Gets all the function selectors supported by a specific facet
        @param _facet The facet address
        @return facetFunctionSelectors_

     **************************************/

    function facetFunctionSelectors(address _facet) external override view returns (bytes4[] memory facetFunctionSelectors_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetFunctionSelectors_ = ds.facetFunctionSelectors[_facet].functionSelectors;
    }

    /**************************************

        Get facet addresses

        ------------------------------

        @notice Get all the facet addresses used by a diamond
        @return facetAddresses_

     **************************************/

    function facetAddresses() external override view returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddresses_ = ds.facetAddresses;
    }

    /**************************************

        Get facet address for selector

        ------------------------------

        @notice Gets the facet that supports the given selector
        @dev If facet is not found return address(0)
        @param _functionSelector The function selector
        @return facetAddress_ The facet address

     **************************************/

    function facetAddress(bytes4 _functionSelector) external override view returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds.selectorToFacetAndPosition[_functionSelector].facetAddress;
    }

    /**************************************

        Supports interface

     **************************************/

    function supportsInterface(bytes4 _interfaceId) external override view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}