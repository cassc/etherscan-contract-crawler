// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    Diamond loupe interface

    ------------------------------

    @author Nick Mudge

 **************************************/

interface IDiamondLoupe {
    // struct
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /**************************************

        Get facets

        ------------------------------

        @notice Gets all facet addresses and their four byte function selectors
        @return facets_ Facet

     **************************************/

    function facets() external view returns (Facet[] memory facets_);

    /**************************************

        Get facet function selectors

        ------------------------------

        @notice Gets all the function selectors supported by a specific facet
        @param _facet The facet address
        @return facetFunctionSelectors_

     **************************************/

    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /**************************************

        Get facet addresses

        ------------------------------

        @notice Get all the facet addresses used by a diamond
        @return facetAddresses_

     **************************************/

    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /**************************************

        Get facet address for selector

        ------------------------------

        @notice Gets the facet that supports the given selector
        @dev If facet is not found return address(0)
        @param _functionSelector The function selector
        @return facetAddress_ The facet address

     **************************************/

    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}