// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @title IDiamondCut
 *
 * @notice Manages Diamond Facets.
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * The ERC-165 identifier for this interface is: 0x1f931c1c
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 */
interface IDiamondCut {
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Cuts facets of the Diamond.
     *
     * Adds/replaces/removes any number of function selectors.
     *
     * If populated, _calldata is executed with delegatecall on _init
     *
     * Reverts if caller does not have UPGRADER role
     *
     * @param _facetCuts - contains the facet addresses and function selectors
     * @param _init - the address of the contract or facet to execute _calldata
     * @param _calldata - a function call, including function selector and arguments
     */
    function diamondCut(FacetCut[] calldata _facetCuts, address _init, bytes calldata _calldata) external;
}