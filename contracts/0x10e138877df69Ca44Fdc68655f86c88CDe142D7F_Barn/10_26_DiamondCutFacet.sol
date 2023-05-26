// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IDiamondCut.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibOwnership.sol";

contract DiamondCutFacet is IDiamondCut {
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
    ) external override {
        LibOwnership.enforceIsContractOwner();

        uint256 selectorCount = LibDiamondStorage.diamondStorage().selectors.length;
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            FacetCut memory cut;
            cut.action = _diamondCut[facetIndex].action;
            cut.facetAddress = _diamondCut[facetIndex].facetAddress;
            cut.functionSelectors = _diamondCut[facetIndex].functionSelectors;

            selectorCount = LibDiamond.executeDiamondCut(selectorCount, cut);
        }

        emit DiamondCut(_diamondCut, _init, _calldata);

        LibDiamond.initializeDiamondCut(_init, _calldata);
    }
}