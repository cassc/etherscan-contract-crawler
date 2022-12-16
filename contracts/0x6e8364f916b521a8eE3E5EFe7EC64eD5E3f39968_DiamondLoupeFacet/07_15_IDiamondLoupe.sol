// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
pragma experimental ABIEncoderV2;

/// @title ERC2535 Diamond Standard, Diamond Loupe.
/// @dev See https://eips.ethereum.org/EIPS/eip-2535
/// @dev Note: the ERC-165 identifier for this interface is 0x48e2b093
interface IDiamondLoupe {
    struct Facet {
        address facet;
        bytes4[] selectors;
    }

    /// @notice Gets all the facet addresses used by the diamond and their function selectors.
    /// @return diamondFacets The facet addresses used by the diamond and their function selectors.
    function facets() external view returns (Facet[] memory diamondFacets);

    /// @notice Gets all the function selectors supported by a facet.
    /// @param facetAddress The facet address.
    /// @return selectors The function selectors supported by `facet`.
    function facetFunctionSelectors(address facetAddress) external view returns (bytes4[] memory selectors);

    /// @notice Get all the facet addresses used by the diamond.
    /// @return diamondFacetsAddresses The facet addresses used by the diamond.
    function facetAddresses() external view returns (address[] memory diamondFacetsAddresses);

    /// @notice Gets the facet address that supports a given function selector.
    /// @param functionSelector The function selector.
    /// @return diamondFacetAddress The facet address that supports `functionSelector`, or the zero address if the facet is not found.
    function facetAddress(bytes4 functionSelector) external view returns (address diamondFacetAddress);
}