// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title IDiamondLoupe
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @notice Required introspection functions for EIP-2535 Diamond Standard
 */
 interface IDiamondLoupe {

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    function facets() external view returns (Facet[] memory facets_);
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);
    function facetAddresses() external view returns (address[] memory facetAddresses_);
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}