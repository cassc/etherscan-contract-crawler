// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @title IDiamondLoupe
 *
 * @notice Provides Diamond Facet inspection functionality.
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * The ERC-165 identifier for this interface is: 0x48e2b093
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 */
interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /**
     *  @notice Gets all facets and their selectors.
     *
     *  @return facets_ - array of Facets
     */
    function facets() external view returns (Facet[] memory facets_);

    /**
     * @notice Gets all the function selectors supported by a specific facet.
     *
     * @param _facet  - the facet address
     * @return facetFunctionSelectors_ - the selectors associated with a facet address
     */
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /**
     * @notice Gets all the facet addresses used by a diamond.
     *
     * @return facetAddresses_ - array of addresses
     */
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /**
     * @notice Gets the facet that supports the given selector.
     *
     * @dev If facet is not found return address(0).
     *
     * @param _functionSelector - the function selector.
     * @return facetAddress_ - the facet address.
     */
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}