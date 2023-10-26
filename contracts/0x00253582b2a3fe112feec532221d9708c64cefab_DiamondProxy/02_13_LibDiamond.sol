// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { LibStorage as s } from "./LibStorage.sol";

import "../../utils/Errors.sol";
import "../Storage.sol";

/// @title LibDiamond
/// @author Angle Labs, Inc.
/// @notice Helper library to deal with diamond proxies.
/// @dev Reference: EIP-2535 Diamonds
/// @dev Forked from https://github.com/mudgen/diamond-3/blob/master/contracts/libraries/LibDiamond.sol by mudgen
library LibDiamond {
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                  INTERNAL FUNCTIONS                                                
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks whether `admin` has the governor role
    function isGovernor(address admin) internal view returns (bool) {
        return s.diamondStorage().accessControlManager.isGovernor(admin);
    }

    /// @notice Checks whether `admin` has the guardian role
    function isGovernorOrGuardian(address admin) internal view returns (bool) {
        return s.diamondStorage().accessControlManager.isGovernorOrGuardian(admin);
    }

    /// @notice Internal function version of `diamondCut`
    function diamondCut(FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        uint256 diamondCutLength = _diamondCut.length;
        for (uint256 facetIndex; facetIndex < diamondCutLength; facetIndex++) {
            bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
            address facetAddress = _diamondCut[facetIndex].facetAddress;

            if (functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacetForCut(facetAddress);
            }

            FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == FacetCutAction.Add) {
                _addFunctions(facetAddress, functionSelectors);
            } else if (action == FacetCutAction.Replace) {
                _replaceFunctions(facetAddress, functionSelectors);
            } else if (action == FacetCutAction.Remove) {
                _removeFunctions(facetAddress, functionSelectors);
            }
        }

        emit DiamondCut(_diamondCut, _init, _calldata);
        _initializeDiamondCut(_init, _calldata);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                   PRIVATE FUNCTIONS                                                
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Does a delegate call on `_init` with `_calldata`
    function _initializeDiamondCut(address _init, bytes memory _calldata) private {
        if (_init == address(0)) {
            return;
        }
        _enforceHasContractCode(_init);
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    /// @notice Adds a new function to the diamond proxy
    /// @dev Reverts if selectors are already existing
    function _addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) private {
        if (_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = s.diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        _enforceHasContractCode(_facetAddress);
        uint256 functionSelectorsLength = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorInfo[selector].facetAddress;
            if (oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }
            ds.selectorInfo[selector] = FacetInfo(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    /// @notice Upgrades a function in the diamond proxy
    /// @dev Reverts if selectors do not already exist
    function _replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) private {
        DiamondStorage storage ds = s.diamondStorage();
        if (_facetAddress == address(0)) {
            revert CannotReplaceFunctionsFromFacetWithZeroAddress(_functionSelectors);
        }
        _enforceHasContractCode(_facetAddress);
        uint256 functionSelectorsLength = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorInfo[selector].facetAddress;
            // Can't replace immutable functions -- functions defined directly in the diamond in this case
            if (oldFacetAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if (oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(selector);
            }
            if (oldFacetAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // Replace old facet address
            ds.selectorInfo[selector].facetAddress = _facetAddress;
        }
    }

    /// @notice Removes a function in the diamond proxy
    /// @dev Reverts if selectors do not already exist
    function _removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) private {
        DiamondStorage storage ds = s.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if (_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }
        uint256 functionSelectorsLength = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetInfo memory oldFacetAddressAndSelectorPosition = ds.selectorInfo[selector];
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }

            // Can't remove immutable functions -- functions defined directly in the diamond
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(this)) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // Replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.selectorInfo[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // Delete last selector
            ds.selectors.pop();
            delete ds.selectorInfo[selector];
        }
    }

    /// @notice Checks that an address has a non void bytecode
    function _enforceHasContractCode(address _contract) private view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert ContractHasNoCode();
        }
    }
}