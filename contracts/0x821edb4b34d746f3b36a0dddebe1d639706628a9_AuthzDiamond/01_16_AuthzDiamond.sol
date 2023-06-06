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

import "../facets/task-executor/TaskExecutorLib.sol";
import "../facets/rbac/RBACLib.sol";
import "./IDiamond.sol";
import "./IDiamondFacet.sol";
import "./FacetManager.sol";
import "./IAuthzDiamondInitializer.sol";
import "./IAuthz.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library AuthzDiamondInfo {
    string public constant VERSION = "2.1.0";
}

contract AuthzDiamond is IDiamond, IAuthzDiamondInitializer {

    string private _name;
    string private _detailsURI;

    address private _initializer;
    bool private _initialized;

    modifier mustBeInitialized() {
        require(_initialized, "ADMND:NI");
        _;
    }

    modifier onlyAuthzDiamondAdmin() {
        require(RBACLib._hasRole(msg.sender, AuthzLib.ROLE_AUTHZ_DIAMOND_ADMIN), "ADMND:MR");
        _;
    }

    constructor(address initializer) {
        _initialized = false;
        _initializer = initializer;
    }

    function initialize(
        string memory name,
        address taskManager,
        address[] memory authzAdmins,
        address[] memory authzDiamondAdmins
    ) external override {
        require(!_initialized, "ADMND:AI");
        require(msg.sender == _initializer, "ADMND:WI");
        _name = name;
        TaskExecutorLib._initialize(taskManager);
        for(uint i = 0; i < authzDiamondAdmins.length; i++) {
            RBACLib._unsafeGrantRole(
                authzDiamondAdmins[i],
                AuthzLib.ROLE_AUTHZ_DIAMOND_ADMIN);
        }
        for(uint i = 0; i < authzAdmins.length; i++) {
            RBACLib._unsafeGrantRole(authzAdmins[i], AuthzLib.ROLE_AUTHZ_ADMIN);
        }
        _initialized = true;
    }

    function supportsInterface(bytes4 interfaceId)
      public view override mustBeInitialized virtual returns (bool) {
        // Querying for IDiamond must always return true
        if (
            interfaceId == 0xd4bbd4bb ||
            interfaceId == type(IDiamond).interfaceId
        ) {
            return true;
        }
        // Querying for IDiamondFacet must always return false
        if (interfaceId == type(IDiamondFacet).interfaceId) {
            return false;
        }
        // Always return true
        if (interfaceId == type(IERC165).interfaceId) {
            return true;
        }
        address[] memory facets = FacetManagerLib._getFacets();
        for (uint256 i = 0; i < facets.length; i++) {
            address facet = facets[i];
            if (!FacetManagerLib._isFacetDeleted(facet) &&
                IDiamondFacet(facet).supportsInterface(interfaceId)) {
                return true;
            }
        }
        return false;
    }

    function isInitialized() external view returns (bool) {
        return _initialized;
    }

    function getDiamondName()
    external view virtual mustBeInitialized override returns (string memory) {
        return _name;
    }

    function getDiamondVersion()
    external view virtual mustBeInitialized override returns (string memory) {
        return AuthzDiamondInfo.VERSION;
    }

    function setDiamondName(
        string memory name
    ) external mustBeInitialized onlyAuthzDiamondAdmin {
        _name = name;
    }

    function getDetailsURI() external view mustBeInitialized returns (string memory) {
        return _detailsURI;
    }

    function setDetailsURI(
        string memory detailsURI
    ) external mustBeInitialized onlyAuthzDiamondAdmin {
        _detailsURI = detailsURI;
    }

    function getTaskManager() external view mustBeInitialized returns (address) {
        return TaskExecutorLib._getTaskManager("DEFAULT");
    }

    function isDiamondFrozen() external view mustBeInitialized returns (bool) {
        return FacetManagerLib._isDiamondFrozen();
    }

    function freezeDiamond(
        string memory taskManagerKey,
        uint256 adminTaskId
    ) external mustBeInitialized onlyAuthzDiamondAdmin {
        FacetManagerLib._freezeDiamond();
        TaskExecutorLib._executeAdminTask(taskManagerKey, adminTaskId);
    }

    function isDiamondLocked() external view mustBeInitialized returns (bool) {
        return FacetManagerLib._isDiamondLocked();
    }

    function setLocked(
        string memory taskManagerKey,
        uint256 taskId,
        bool locked
    ) external mustBeInitialized onlyAuthzDiamondAdmin {
        FacetManagerLib._setLocked(locked);
        TaskExecutorLib._executeTask(taskManagerKey, taskId);
    }

    function getFacets()
    external view mustBeInitialized override returns (address[] memory) {
        return FacetManagerLib._getFacets();
    }

    function resolve(string[] memory funcSigs)
    external view mustBeInitialized returns (address[] memory) {
        return FacetManagerLib._resolve(funcSigs);
    }

    function addFacets(
        address[] memory facets
    ) external mustBeInitialized onlyAuthzDiamondAdmin {
        FacetManagerLib._addFacets(facets);
    }

    function deleteFacets(
        address[] memory facets
    ) external mustBeInitialized onlyAuthzDiamondAdmin {
        FacetManagerLib._deleteFacets(facets);
    }

    function replaceFacets(
        address[] memory toBeDeletedFacets,
        address[] memory toBeAddedFacets
    ) external mustBeInitialized onlyAuthzDiamondAdmin {
        FacetManagerLib._replaceFacets(toBeDeletedFacets, toBeAddedFacets);
    }

    function deleteAllFacets() external mustBeInitialized onlyAuthzDiamondAdmin {
        FacetManagerLib._deleteAllFacets();
    }

    function overrideFuncSigs(
        string[] memory funcSigs,
        address[] memory facets
    ) external mustBeInitialized onlyAuthzDiamondAdmin {
        FacetManagerLib._overrideFuncSigs(funcSigs, facets);
    }

    function getOverridenFuncSigs()
    external view mustBeInitialized returns (string[] memory) {
        return FacetManagerLib._getOverridenFuncSigs();
    }

    /* solhint-disable no-complex-fallback */
    fallback() external payable {
        require(_initialized, "ADMND:NI");
        address facet = FacetManagerLib._findFacet(msg.sig);
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