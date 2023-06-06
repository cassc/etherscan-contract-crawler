/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./IDiamondFacet.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library FacetManagerStorage {

    struct Layout {
        // true if diamond is frozen meaning it cannot be changed anymore.
        // ATTENTION! once frozen, one WILL NEVER be able to undo that.
        bool diamondFrozen;
        // true if diamond is locked, meaning it cannot be changed anymore.
        // diamonds can be unlocked.
        bool diamondLocked;
        // list of facet addersses
        address[] facets;
        mapping(address => uint256) facetsIndex;
        // facet address > true if marked as deleted
        mapping(address => bool) deletedFacets;
        // function selector > facet address
        mapping(bytes4 => address) selectorToFacetMap;
        // list of overriden function signatures
        string[] overridenFuncSigs;
        mapping(string => uint256) overridenFuncSigsIndex;
        // facet address > true if frozen
        mapping(address => bool) frozenFacets;
        // function signature > true if protected
        mapping(bytes4 => bool) protectedSelectorMap;
        // Extra fields (reserved for future)
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.diamond.facet-manager.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

library FacetManagerLib {

    event FacetAdd(address facet);
    event FacetDelete(address facet);
    event FreezeDiamond();
    event SetLocked(bool locked);
    event FuncSigOverride(string funcSig, address facet);
    event ProtectFuncSig(string funcSig, bool protect);

    function _isDiamondFrozen() internal view returns (bool) {
        return __s().diamondFrozen;
    }

    function _freezeDiamond() internal {
        require(!__s().diamondFrozen, "FMLIB:DFRZN");
        __s().diamondFrozen = true;
        emit FreezeDiamond();
    }

    function _isFacetFrozen(address facet) internal view returns (bool) {
        return __s().frozenFacets[facet];
    }

    function _freezeFacet(address facet) internal {
        require(!__s().diamondFrozen, "FMLIB:DFRZN");
        require(facet != address(0), "FMLIB:ZF");
        require(!__s().frozenFacets[facet], "FMLIB:FAF");
        __s().frozenFacets[facet] = true;
    }

    function _isDiamondLocked() internal view returns (bool) {
        return __s().diamondLocked;
    }

    function _setLocked(bool locked) internal {
        require(!__s().diamondFrozen, "FMLIB:DFRZN");
        __s().diamondLocked = locked;
        emit SetLocked(locked);
    }

    function _getFacets() internal view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < __s().facets.length; i++) {
            if (!__s().deletedFacets[__s().facets[i]]) {
                count += 1;
            }
        }
        address[] memory facets = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < __s().facets.length; i++) {
            if (!__s().deletedFacets[__s().facets[i]]) {
                facets[index] = __s().facets[i];
                index += 1;
            }
        }
        return facets;
    }

    function _resolve(string[] memory funcSigs) internal view returns (address[] memory) {
        address[] memory facets = new address[](funcSigs.length);
        for (uint256 i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            bytes4 selector = _getSelector(funcSig);
            facets[i] = __s().selectorToFacetMap[selector];
            if (__s().deletedFacets[facets[i]]) {
                facets[i] = address(0);
            }
        }
        return facets;
    }

    function _areFuncSigsProtected(
        string[] memory funcSigs
    ) internal view returns (bool[] memory) {
        bool[] memory results = new bool[](funcSigs.length);
        for (uint256 i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            bytes4 selector = _getSelector(funcSig);
            results[i] = __s().protectedSelectorMap[selector];
        }
        return results;
    }

    function _protectFuncSig(
        string memory funcSig,
        bool protect
    ) internal {
        require(!__s().diamondLocked, "FMLIB:LCKD");
        __protectFuncSig(funcSig, protect);
    }

    function _isSelectorProtected(bytes4 funcSelector) internal view returns (bool) {
        return __s().protectedSelectorMap[funcSelector];
    }

    function _addFacets(address[] memory facets) internal {
        require(!__s().diamondFrozen, "FMLIB:DFRZN");
        require(!__s().diamondLocked, "FMLIB:LCKD");
        require(facets.length > 0, "FMLIB:ZL");
        for (uint256 i = 0; i < facets.length; i++) {
            _addFacet(facets[i]);
        }
    }

    function _deleteFacets(address[] memory facets) internal {
        require(!__s().diamondFrozen, "FMLIB:DFRZN");
        require(!__s().diamondLocked, "FMLIB:LCKD");
        require(facets.length > 0, "FMLIB:ZL");
        for (uint256 i = 0; i < facets.length; i++) {
            __deleteFacet(facets[i]);
        }
    }

    function _replaceFacets(
        address[] memory toBeDeletedFacets,
        address[] memory toBeAddedFacets
    ) internal {
        _deleteFacets(toBeDeletedFacets);
        _addFacets(toBeAddedFacets);
    }

    function _isFacetDeleted(address facet) internal view returns (bool) {
        return __s().deletedFacets[facet];
    }

    function _deleteAllFacets() internal {
        require(!__s().diamondFrozen, "FMLIB:DFRZN");
        require(!__s().diamondLocked, "FMLIB:LCKD");
        for (uint256 i = 0; i < __s().facets.length; i++) {
            __deleteFacet(__s().facets[i]);
        }
    }

    function _overrideFuncSigs(
        string[] memory funcSigs,
        address[] memory facets
    ) internal {
        require(!__s().diamondFrozen, "FMLIB:DFRZN");
        require(!__s().diamondLocked, "FMLIB:LCKD");
        __overrideFuncSigs(funcSigs, facets);
    }

    function _getOverridenFuncSigs() internal view returns (string[] memory) {
        return __s().overridenFuncSigs;
    }

    function _findFacet(bytes4 selector) internal view returns (address) {
        address facet = __s().selectorToFacetMap[selector];
        require(facet != address(0), "FMLIB:FNF");
        require(!__s().deletedFacets[facet], "FMLIB:FREM");
        return facet;
    }

    function _addFacet(address facet) internal {
        require(!__s().diamondFrozen, "FMLIB:DFRZN");
        require(!__s().diamondLocked, "FMLIB:LCKD");
        require(facet != address(0), "FMLIB:ZF");
        require(
            IDiamondFacet(facet).supportsInterface(type(IDiamondFacet).interfaceId),
            "FMLIB:IF"
        );
        string[] memory funcSigs = IDiamondFacet(facet).getFacetPI();
        for (uint256 i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            bytes4 selector = _getSelector(funcSig);
            address currentFacet = __s().selectorToFacetMap[selector];
            if (currentFacet != address(0)) {
                // current facet must not be frozen
                require(!__s().frozenFacets[currentFacet], "FMLIB:FF");
            }
            __s().selectorToFacetMap[selector] = facet;
            __protectFuncSig(funcSig, false);
        }
        string[] memory protectedFuncSigs = IDiamondFacet(facet).getFacetProtectedPI();
        for (uint256 i = 0; i < protectedFuncSigs.length; i++) {
            string memory protectedFuncSig = protectedFuncSigs[i];
            __protectFuncSig(protectedFuncSig, true);
        }
        __s().deletedFacets[facet] = false;
        // update facets array
        if (__s().facetsIndex[facet] == 0) {
            __s().facets.push(facet);
            __s().facetsIndex[facet] = __s().facets.length;
        }
        emit FacetAdd(facet);
    }

    function _getSelector(string memory funcSig) internal pure returns (bytes4) {
        bytes memory funcSigBytes = bytes(funcSig);
        for (uint256 i = 0; i < funcSigBytes.length; i++) {
            bytes1 b = funcSigBytes[i];
            if (
                !(b >= 0x30 && b <= 0x39) && // [0-9]
                !(b >= 0x41 && b <= 0x5a) && // [A-Z]
                !(b >= 0x61 && b <= 0x7a) && // [a-z]
                 b != 0x24 && // $
                 b != 0x5f && // _
                 b != 0x2c && // ,
                 b != 0x28 && // (
                 b != 0x29 && // )
                 b != 0x5b && // [
                 b != 0x5d    // ]
            ) {
                revert("FMLIB:IFS");
            }
        }
        return bytes4(keccak256(bytes(funcSig)));
    }

    function __deleteFacet(address facet) private {
        require(facet != address(0), "FMLIB:ZF");
        require(!__s().frozenFacets[facet], "FMLIB:FF");
        __s().deletedFacets[facet] = true;
        emit FacetDelete(facet);
    }

    function __overrideFuncSigs(
        string[] memory funcSigs,
        address[] memory facets
    ) private {
        require(funcSigs.length > 0, "FMLIB:ZL");
        require(funcSigs.length == facets.length, "FMLIB:IL");
        for (uint i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            address facet = facets[i];
            bytes4 selector = _getSelector(funcSig);
            address currentFacet = __s().selectorToFacetMap[selector];
            if (currentFacet != address(0)) {
                // current facet must not be frozen
                require(!__s().frozenFacets[currentFacet], "FMLIB:FF");
            }
            __s().selectorToFacetMap[selector] = facet;
            __s().deletedFacets[facet] = false;
            if (__s().overridenFuncSigsIndex[funcSig] == 0) {
                __s().overridenFuncSigs.push(funcSig);
                __s().overridenFuncSigsIndex[funcSig] = __s().overridenFuncSigs.length;
            }
            emit FuncSigOverride(funcSig, facet);
        }
    }

    function __protectFuncSig(string memory funcSig, bool protect) private {
        bytes4 selector = _getSelector(funcSig);
        bool oldValue = __s().protectedSelectorMap[selector];
        __s().protectedSelectorMap[selector] = protect;
        if (oldValue != protect) {
            emit ProtectFuncSig(funcSig, protect);
        }
    }

    function __s() private pure returns (FacetManagerStorage.Layout storage) {
        return FacetManagerStorage.layout();
    }
}