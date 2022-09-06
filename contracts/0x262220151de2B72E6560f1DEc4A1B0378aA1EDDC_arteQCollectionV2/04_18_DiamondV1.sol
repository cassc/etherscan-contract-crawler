/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
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

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "../security/task-executor/TaskExecutorFacet.sol";
import "../security/task-executor/TaskExecutorLib.sol";
import "../security/role-manager/RoleManagerFacet.sol";
import "../security/role-manager/RoleManagerLib.sol";
import "./IDiamondFacet.sol";
import "./DiamondV1Config.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract DiamondV1 is
  IERC165,
  TaskExecutorFacet,
  RoleManagerFacet
{
    address[] private _facets;
    mapping(address => uint256) private _facetArrayIndex;
    mapping(bytes4 => address) private _selectorToFacetMap;
    mapping(address => string[]) private _facetToFuncSigsMap;
    mapping(address => mapping(bytes4 => bool)) private _removedFuncs;
    mapping(bytes4 => bool) private _suppressedInterfaceIds;

    modifier onlyDiamondAdmin() {
        RoleManagerLib._checkRole(DiamondV1Config.ROLE_DIAMOND_ADMIN);
        _;
    }

    constructor(
        address taskManager,
        address[] memory diamondAdmins
    ) {
        TaskExecutorLib._setTaskManager(taskManager);
        for(uint i = 0; i < diamondAdmins.length; i++) {
            RoleManagerLib._grantRole(diamondAdmins[i], DiamondV1Config.ROLE_DIAMOND_ADMIN);
        }
    }

    function supportsInterface(bytes4 interfaceId)
      public view override virtual returns (bool) {
        // Querying for IDiamondFacet must always return false
        if (interfaceId == type(IDiamondFacet).interfaceId) {
            return false;
        }
        if (_suppressedInterfaceIds[interfaceId]) {
            return false;
        }
        // Always return true
        if (interfaceId == type(IERC165).interfaceId) {
            return true;
        }
        for (uint256 i = 0; i < _facets.length; i++) {
            address facet = _facets[i];
            if (IDiamondFacet(facet).supportsInterface(interfaceId)) {
                return true;
            }
        }
        return false;
    }

    function isInterfaceIdSuppressed(bytes4 interfaceId)
      external view onlyDiamondAdmin returns (bool) {
        return _suppressedInterfaceIds[interfaceId];
    }

    function suppressInterfaceId(bytes4 interfaceId, bool suppress)
      external onlyDiamondAdmin {
        _suppressedInterfaceIds[interfaceId] = suppress;
    }

    function getFuncs()
      external view onlyDiamondAdmin returns (string[] memory, address[] memory) {
        return _getFuncs();
    }

    function getFacetFuncs(address facet)
      external view onlyDiamondAdmin returns (string[] memory) {
        return _getFacetFuncs(facet);
    }

    function addFuncs(
        string[] memory funcSigs,
        address[] memory facets
    ) external onlyDiamondAdmin {
        require(funcSigs.length > 0, "DV1:ZL");
        require(funcSigs.length == facets.length, "DV1:NEQL");
        for (uint256 i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            address facet = facets[i];
            _addFunc(funcSig, facet);
        }
    }

    function removeFuncs(
        string[] memory funcSigs
    ) external onlyDiamondAdmin {
        require(funcSigs.length > 0, "DV1:ZL");
        for (uint256 i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            _removeFunc(funcSig);
        }
    }

    function _getFuncs() internal view returns (string[] memory, address[] memory) {
        uint256 length = 0;
        for (uint256 i = 0; i < _facets.length; i++) {
            address facet = _facets[i];
            string[] memory facetFuncs = _getFacetFuncs(facet);
            for (uint256 j = 0; j < facetFuncs.length; j++) {
                length += 1;
            }
        }
        string[] memory funcSigs = new string[](length);
        address[] memory facets = new address[](length);
        uint256 index = 0;
        for (uint256 i = 0; i < _facets.length; i++) {
            address facet = _facets[i];
            string[] memory facetFuncs = _getFacetFuncs(facet);
            for (uint256 j = 0; j < facetFuncs.length; j++) {
                funcSigs[index] = facetFuncs[j];
                facets[index] = facet;
                index += 1;
            }
        }
        return (funcSigs, facets);
    }

    function _getFacetFuncs(address facet) internal view returns (string[] memory) {
        uint256 length = 0;
        for (uint256 j = 0; j < _facetToFuncSigsMap[facet].length; j++) {
            string memory funcSig = _facetToFuncSigsMap[facet][j];
            bytes4 selector = __getSelector(funcSig);
            if (!_removedFuncs[facet][selector]) {
                length += 1;
            }
        }
        string[] memory funcSigs = new string[](length);
        uint256 index = 0;
        for (uint256 j = 0; j < _facetToFuncSigsMap[facet].length; j++) {
            string memory funcSig = _facetToFuncSigsMap[facet][j];
            bytes4 selector = __getSelector(funcSig);
            if (!_removedFuncs[facet][selector]) {
                funcSigs[index] = funcSig;
                index += 1;
            }
        }
        return funcSigs;
    }

    function _addFunc(
        string memory funcSig,
        address facet
    ) internal {
        require(facet != address(0), "DV1:ZF");
        require(
            IDiamondFacet(facet).supportsInterface(type(IDiamondFacet).interfaceId),
            "DV1:IF"
        );
        bytes4 selector = __getSelector(funcSig);
        address oldFacet = _selectorToFacetMap[selector];

         // overrides the previously set selector
        _selectorToFacetMap[selector] = facet;

        bool found = false;
        for (uint256 i = 0; i < _facetToFuncSigsMap[facet].length; i++) {
            bytes32 s = __getSelector(_facetToFuncSigsMap[facet][i]);
            if (s == selector) {
                found = true;
                break;
            }
        }
        if (!found) {
            _facetToFuncSigsMap[facet].push(funcSig); // add the func-sig to facet's map
        }

        _removedFuncs[facet][selector] = false; // revive the selector if already removed
        if (oldFacet != address(0) && oldFacet != facet) {
            _removedFuncs[oldFacet][selector] = true; // remove from the old facet
        }

        // update facets array
        if (_facetArrayIndex[facet] == 0) {
            _facets.push(facet);
            _facetArrayIndex[facet] = _facets.length;
        }
    }

    function _removeFunc(
        string memory funcSig
    ) internal {
        bytes4 selector = __getSelector(funcSig);
        address facet = _selectorToFacetMap[selector];
        if (facet != address(0)) {
            _removedFuncs[facet][selector] = true;
        }
    }

    function _findFacet(bytes4 selector) internal view returns (address) {
        address facet = _selectorToFacetMap[selector];
        require(facet != address(0), "DV1:FNF");
        require(!_removedFuncs[facet][selector], "DV1:FR");
        return facet;
    }

    function __getSelector(string memory funcSig) private pure returns (bytes4) {
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
                revert("DV1:IFS");
            }
        }
        return bytes4(keccak256(bytes(funcSig)));
    }
}