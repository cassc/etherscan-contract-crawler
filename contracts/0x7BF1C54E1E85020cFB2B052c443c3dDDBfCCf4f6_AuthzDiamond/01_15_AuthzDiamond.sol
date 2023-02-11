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

import "../security/task-executor/TaskExecutorBase.sol";
import "../security/task-executor/TaskExecutorLib.sol";
import "../security/role-manager/RoleManagerBase.sol";
import "../security/role-manager/RoleManagerLib.sol";
import "../diamond/IDiamond.sol";
import "../diamond/IDiamondFacet.sol";
import "./IAuthz.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract AuthzDiamond is
  IDiamond,
  TaskExecutorBase,
  RoleManagerBase
{
    event FacetAdd(address facet);
    event FacetDelete(address facet);
    event FreezeDiamond();
    event FuncSigOverride(string funcSig, address facet);

    string private _name;
    string private _detailsURI;
    bool private _diamondFrozen;
    address[] internal _facets;
    mapping(address => uint256) private _facetArrayIndex;
    mapping(address => bool) private _deletedFacets;
    mapping(bytes4 => address) private _selectorToFacetMap;

    string[] private _overridenFuncSigs;
    mapping(string => uint256) private _overridenFuncSigsIndex;

    modifier notFrozenDiamond {
        require(!_diamondFrozen, "DMND:DFRZN");
        _;
    }

    modifier onlyAuthzDiamondAdmin() {
        RoleManagerLib._checkRole(AuthzLib.ROLE_AUTHZ_DIAMOND_ADMIN);
        _;
    }

    constructor(
        string memory name,
        address taskManager,
        address[] memory authzAdmins,
        address[] memory authzDiamondAdmins
    ) {
        _name = name;
        _diamondFrozen = false;
        TaskExecutorLib._setTaskManager(taskManager);
        for(uint i = 0; i < authzDiamondAdmins.length; i++) {
            RoleManagerLib._grantRole(
                authzDiamondAdmins[i],
                AuthzLib.ROLE_AUTHZ_DIAMOND_ADMIN);
        }
        for(uint i = 0; i < authzAdmins.length; i++) {
            RoleManagerLib._grantRole(authzAdmins[i], AuthzLib.ROLE_AUTHZ_ADMIN);
        }
    }

    function supportsInterface(bytes4 interfaceId)
      public view override virtual returns (bool) {
        // Querying for IDiamondFacet must always return false
        if (interfaceId == type(IDiamondFacet).interfaceId) {
            return false;
        }
        // Always return true
        if (interfaceId == type(IERC165).interfaceId) {
            return true;
        }
        for (uint256 i = 0; i < _facets.length; i++) {
            address facet = _facets[i];
            if (!_deletedFacets[facet] &&
                IDiamondFacet(facet).supportsInterface(interfaceId)) {
                return true;
            }
        }
        return false;
    }

    function getDiamondName() external view virtual override returns (string memory) {
        return _name;
    }

    function getDiamondVersion() external view virtual override returns (string memory) {
        return "1.0.0";
    }

    function setDiamondName(string memory name) external onlyAuthzDiamondAdmin {
        _name = name;
    }

    function getDetailsURI() external view returns (string memory) {
        return _detailsURI;
    }

    function setDetailsURI(string memory detailsURI) external onlyAuthzDiamondAdmin {
        _detailsURI = detailsURI;
    }

    function isDiamondFrozen() external view returns (bool) {
        return _diamondFrozen;
    }

    function freezeDiamond() external notFrozenDiamond onlyAuthzDiamondAdmin {
        _diamondFrozen = true;
        emit FreezeDiamond();
    }

    function getFacets() external view override returns (address[] memory) {
        return __getFacets();
    }

    function resolve(string[] memory funcSigs) external view returns (address[] memory) {
        return __resolve(funcSigs);
    }

    function addFacets(
        address[] memory facets
    ) external notFrozenDiamond onlyAuthzDiamondAdmin {
        require(facets.length > 0, "ADMND:ZL");
        for (uint256 i = 0; i < facets.length; i++) {
            __addFacet(facets[i]);
        }
    }

    function deleteFacets(
        address[] memory facets
    ) external notFrozenDiamond onlyAuthzDiamondAdmin {
        require(facets.length > 0, "ADMND:ZL");
        for (uint256 i = 0; i < facets.length; i++) {
            __deleteFacet(facets[i]);
        }
    }

    function deleteAllFacets() external notFrozenDiamond onlyAuthzDiamondAdmin {
        for (uint256 i = 0; i < _facets.length; i++) {
            __deleteFacet(_facets[i]);
        }
    }

    // WARN: Never use this function directly. The proper way is to add a facet
    //       as a whole.
    function overrideFuncSigs(
        string[] memory funcSigs,
        address[] memory facets
    ) external notFrozenDiamond onlyAuthzDiamondAdmin {
        __overrideFuncSigs(funcSigs, facets);
    }

    function getOverridenFuncSigs() external view returns (string[] memory) {
        return _overridenFuncSigs;
    }

    function _findFacet(bytes4 selector) internal view returns (address) {
        address facet = _selectorToFacetMap[selector];
        require(facet != address(0), "ADMND:FNF");
        require(!_deletedFacets[facet], "ADMND:FREM");
        return facet;
    }

    function __getFacets() private view returns (address[] memory) {
        uint256 count = 0;
        {
            for (uint256 i = 0; i < _facets.length; i++) {
                if (!_deletedFacets[_facets[i]]) {
                    count += 1;
                }
            }
        }
        address[] memory facets = new address[](count);
        {
            uint256 index = 0;
            for (uint256 i = 0; i < _facets.length; i++) {
                if (!_deletedFacets[_facets[i]]) {
                    facets[index] = _facets[i];
                    index += 1;
                }
            }
        }
        return facets;
    }

    function __resolve(string[] memory funcSigs) private view returns (address[] memory) {
        address[] memory facets = new address[](funcSigs.length);
        for (uint256 i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            bytes4 selector = __getSelector(funcSig);
            facets[i] = _selectorToFacetMap[selector];
            if (_deletedFacets[facets[i]]) {
                facets[i] = address(0);
            }
        }
        return facets;
    }

    function __addFacet(address facet) private {
        require(facet != address(0), "ADMND:ZF");
        require(
            IDiamondFacet(facet).supportsInterface(type(IDiamondFacet).interfaceId),
            "ADMND:IF"
        );
        string[] memory funcSigs = IDiamondFacet(facet).getFacetPI();
        for (uint256 i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            bytes4 selector = __getSelector(funcSig);
            _selectorToFacetMap[selector] = facet;
        }
        _deletedFacets[facet] = false;
        // update facets array
        if (_facetArrayIndex[facet] == 0) {
            _facets.push(facet);
            _facetArrayIndex[facet] = _facets.length;
        }
        emit FacetAdd(facet);
    }

    function __deleteFacet(address facet) private {
        require(facet != address(0), "ADMND:ZF");
        _deletedFacets[facet] = true;
        emit FacetDelete(facet);
    }

    function __overrideFuncSigs(
        string[] memory funcSigs,
        address[] memory facets
    ) private {
        require(funcSigs.length > 0, "ADMND:ZL");
        require(funcSigs.length == facets.length, "ADMND:IL");
        for (uint i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            address facet = facets[i];
            bytes4 selector = __getSelector(funcSig);
            _selectorToFacetMap[selector] = facet;
            _deletedFacets[facet] = false;
            if (_overridenFuncSigsIndex[funcSig] == 0) {
                _overridenFuncSigs.push(funcSig);
                _overridenFuncSigsIndex[funcSig] = _overridenFuncSigs.length;
            }
            emit FuncSigOverride(funcSig, facet);
        }
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
                revert("ADMND:IFS");
            }
        }
        return bytes4(keccak256(bytes(funcSig)));
    }

    /* solhint-disable no-complex-fallback */
    fallback() external payable {
        address facet = _findFacet(msg.sig);
        /* solhint-disable no-inline-assembly */
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
        /* solhint-enable no-inline-assembly */
    }

    /* solhint-disable no-empty-blocks */
    receive() external payable {}
    /* solhint-enable no-empty-blocks */
}