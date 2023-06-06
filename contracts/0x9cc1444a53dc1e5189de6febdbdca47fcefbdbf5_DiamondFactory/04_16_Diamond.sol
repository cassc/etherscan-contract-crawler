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
import "./IAppRegistry.sol";
import "./IAuthz.sol";
import "./IDiamond.sol";
import "./IDiamondInitializer.sol";
import "./IDiamondFacet.sol";
import "./FacetManager.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library DiamondInfo {
    string public constant VERSION = "3.1.0";
}

contract Diamond is IDiamond, IDiamondInitializer {

    string private _name;
    string private _detailsURI;

    event FreezeAuthz();
    event AppInstall(address appRegistry, string name, string version);
    event AppRegistrySet(address appRegistry);

    struct Authz {
        bool frozen;
        address source;
        string domain;
        uint256[] acceptedResults;
        string hashSalt;
    }
    Authz private _authz;

    bytes4[] private _defaultSupportingInterfceIds;

    address private _appRegistry;

    address private _initializer;
    bool private _initialized;

    modifier mustBeInitialized {
        require(_initialized, "DMND:NI");
        _;
    }

    modifier notFrozenAuthz {
        require(!_authz.frozen, "DMND:AFRZN");
        _;
    }

    modifier mutatorAuthz {
        _authorizeCall(msg.sender, address(this), msg.sig, true);
        _;
    }

    modifier getterAuthz {
        _authorizeCall(msg.sender, address(this), msg.sig, false);
        _;
    }

    constructor(
        bytes4[] memory defaultSupportingInterfceIds,
        address initializer
    ) {
        _initialized = false;
        _authz.hashSalt = "Dwt2wb1d976h";
        _authz.acceptedResults.push(AuthzLib.ACCEPT_ACTION);
        _defaultSupportingInterfceIds = defaultSupportingInterfceIds;
        _initializer = initializer;
    }

    function initialize(
        string memory name,
        address taskManager,
        address appRegistry,
        address authzSource,
        string memory authzDomain,
        string[][2] memory defaultApps, // [0] > names, [1] > versions
        address[] memory defaultFacets,
        string[][2] memory defaultFuncSigsToProtectOrUnprotect, // [0] > protect, [1] > unprotect
        address[] memory defaultFacetsToFreeze,
        bool[3] memory instantLockAndFreezes // [0] > lock, [1] > freeze-authz, [2] > freeze-diamond
    ) external override {
        require(!_initialized, "DMND:AI");
        require(msg.sender == _initializer, "DMND:WI");
        _name = name;
        TaskExecutorLib._initialize(taskManager);
        __setAppRegistry(appRegistry);
        __setAuthzSource(authzSource);
        _authz.domain = authzDomain;
        require(defaultApps[0].length == defaultApps[1].length, "DMND:WL");
        for (uint256 i = 0; i < defaultApps[0].length; i++) {
            __installApp(
                defaultApps[0][i], // name
                defaultApps[1][i], // version
                false // don't delete current facets
            );
        }
        // install default facets
        for (uint256 i = 0; i < defaultFacets.length; i++) {
            FacetManagerLib._addFacet(defaultFacets[i]);
        }
        // protect default functions
        for (uint256 i = 0; i < defaultFuncSigsToProtectOrUnprotect[0].length; i++) {
            FacetManagerLib._protectFuncSig(
                defaultFuncSigsToProtectOrUnprotect[0][i],
                true // protect
            );
        }
        // unprotect default functions
        for (uint256 i = 0; i < defaultFuncSigsToProtectOrUnprotect[1].length; i++) {
            FacetManagerLib._protectFuncSig(
                defaultFuncSigsToProtectOrUnprotect[1][i],
                false // unprotect
            );
        }
        // lock the diamond if asked for
        if (instantLockAndFreezes[0]) {
            FacetManagerLib._setLocked(true);
        }
        // freeze facets
        for (uint256 i = 0; i < defaultFacetsToFreeze.length; i++) {
            FacetManagerLib._freezeFacet(defaultFacetsToFreeze[i]);
        }
        // freeze the authz settings if asked for
        if (instantLockAndFreezes[1]) {
            _authz.frozen = true;
        }
        // freeze the diamond if asked for
        if (instantLockAndFreezes[2]) {
            FacetManagerLib._freezeDiamond();
        }
        _initialized = true;
    }


    function supportsInterface(bytes4 interfaceId)
      public view override getterAuthz virtual returns (bool) {
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
        for (uint256 i = 0; i < _defaultSupportingInterfceIds.length; i++) {
            if (interfaceId == _defaultSupportingInterfceIds[i]) {
                return true;
            }
        }
        return false;
    }

    function isInitialized() external view returns (bool) {
        return _initialized;
    }

    function getDiamondName()
    external view virtual override mustBeInitialized getterAuthz returns (string memory) {
        return _name;
    }

    function getDiamondVersion()
    external view virtual override mustBeInitialized getterAuthz  returns (string memory) {
        return DiamondInfo.VERSION;
    }

    function setDiamondName(string memory name) external mustBeInitialized mutatorAuthz {
        _name = name;
    }

    function getDetailsURI()
    external view mustBeInitialized getterAuthz returns (string memory) {
        return _detailsURI;
    }

    function setDetailsURI(string memory detailsURI) external mustBeInitialized mutatorAuthz {
        _detailsURI = detailsURI;
    }

    function getTaskManager() external view mustBeInitialized getterAuthz returns (address) {
        return TaskExecutorLib._getTaskManager("DEFAULT");
    }

    function getAuthzSource() external view mustBeInitialized getterAuthz returns (address) {
        return _authz.source;
    }

    function setAuthzSource(
        address authzSource
    ) external mustBeInitialized notFrozenAuthz mutatorAuthz {
        __setAuthzSource(authzSource);
    }

    function getAuthzDomain() external view mustBeInitialized getterAuthz returns (string memory) {
        return _authz.domain;
    }

    function setAuthzDomain(
        string memory authzDomain
    ) external mustBeInitialized notFrozenAuthz mutatorAuthz {
        require(bytes(authzDomain).length > 0, "DMND:ED");
        _authz.domain = authzDomain;
    }

    function getAcceptedAuthzResults()
    external view mustBeInitialized getterAuthz returns (uint256[] memory) {
        return _authz.acceptedResults;
    }

    function setAcceptedAuthzResults(
        uint256[] memory acceptedAuthzResults
    ) external mustBeInitialized notFrozenAuthz mutatorAuthz {
        require(acceptedAuthzResults.length > 0, "DMND:EA");
        _authz.acceptedResults = acceptedAuthzResults;
    }

    function getAppRegistry() external view mustBeInitialized getterAuthz returns (address) {
        return _appRegistry;
    }

    function setAppRegistry(address appRegistry) external mustBeInitialized mutatorAuthz {
        __setAppRegistry(appRegistry);
    }

    function isDiamondFrozen() external view mustBeInitialized getterAuthz returns (bool) {
        return FacetManagerLib._isDiamondFrozen();
    }

    function freezeDiamond(
        string memory taskManagerKey,
        uint256 adminTaskId
    ) external mustBeInitialized mutatorAuthz {
        FacetManagerLib._freezeDiamond();
        TaskExecutorLib._executeAdminTask(taskManagerKey, adminTaskId);
    }

    function isFacetFrozen(address facet)
    external view mustBeInitialized getterAuthz returns (bool) {
        return FacetManagerLib._isFacetFrozen(facet);
    }

    function freezeFacet(
        string memory taskManagerKey,
        uint256 adminTaskId,
        address facet
    ) external mustBeInitialized mutatorAuthz {
        FacetManagerLib._freezeFacet(facet);
        TaskExecutorLib._executeAdminTask(taskManagerKey, adminTaskId);
    }

    function isAuthzFrozen() external view mustBeInitialized getterAuthz returns (bool) {
        return _authz.frozen;
    }

    function freezeAuthz(
        string memory taskManagerKey,
        uint256 adminTaskId
    ) external mustBeInitialized notFrozenAuthz mutatorAuthz {
        _authz.frozen = true;
        emit FreezeAuthz();
        TaskExecutorLib._executeAdminTask(taskManagerKey, adminTaskId);
    }

    function isDiamondLocked() external view mustBeInitialized getterAuthz returns (bool) {
        return FacetManagerLib._isDiamondLocked();
    }

    function setLocked(
        string memory taskManagerKey,
        uint256 taskId,
        bool locked
    ) external mustBeInitialized mutatorAuthz {
        FacetManagerLib._setLocked(locked);
        TaskExecutorLib._executeTask(taskManagerKey, taskId);
    }

    function getFacets()
    external view override mustBeInitialized getterAuthz returns (address[] memory) {
        return FacetManagerLib._getFacets();
    }

    function resolve(string[] memory funcSigs)
    external view mustBeInitialized getterAuthz returns (address[] memory) {
        return FacetManagerLib._resolve(funcSigs);
    }

    function areFuncSigsProtected(
        string[] memory funcSigs
    ) external view mustBeInitialized getterAuthz returns (bool[] memory) {
        return FacetManagerLib._areFuncSigsProtected(funcSigs);
    }

    function protectFuncSig(string memory funcSig, bool protect)
    external mustBeInitialized notFrozenAuthz mutatorAuthz {
        FacetManagerLib._protectFuncSig(funcSig, protect);
    }

    function addFacets(address[] memory facets) external mustBeInitialized mutatorAuthz {
        FacetManagerLib._addFacets(facets);
    }

    function deleteFacets(address[] memory facets) external mustBeInitialized mutatorAuthz {
        FacetManagerLib._deleteFacets(facets);
    }

    function replaceFacets(
        address[] memory toBeDeletedFacets,
        address[] memory toBeAddedFacets
    ) external mustBeInitialized mutatorAuthz {
        FacetManagerLib._replaceFacets(toBeDeletedFacets, toBeAddedFacets);
    }

    function deleteAllFacets() external mustBeInitialized mutatorAuthz {
        FacetManagerLib._deleteAllFacets();
    }

    function installApp(
        string memory appName,
        string memory appVersion,
        bool deleteCurrentFacets
    ) external mustBeInitialized mutatorAuthz {
        __installApp(appName, appVersion, deleteCurrentFacets);
    }

    function overrideFuncSigs(
        string[] memory funcSigs,
        address[] memory facets
    ) external mustBeInitialized mutatorAuthz {
        FacetManagerLib._overrideFuncSigs(funcSigs, facets);
    }

    function getOverridenFuncSigs()
    external view mustBeInitialized getterAuthz returns (string[] memory) {
        return FacetManagerLib._getOverridenFuncSigs();
    }

    function tryAuthorizeCall(
        address caller,
        string memory funcSig
    ) external view mustBeInitialized getterAuthz {
        address facet = FacetManagerLib._findFacet(msg.sig);
        bytes4 funcSelector = FacetManagerLib._getSelector(funcSig);
        _authorizeCall(caller, facet, funcSelector, false);
    }

    function _authorizeCall(
        address caller,
        address facet,
        bytes4 funcSelector,
        bool treatAsProtected
    ) internal view {
        if (!treatAsProtected && !FacetManagerLib._isSelectorProtected(funcSelector)) {
            return;
        }
        require(_authz.source != address(0), "DMND:ZA");
        bytes32 domainHash = keccak256(abi.encodePacked(_authz.hashSalt, _authz.domain));
        bytes32 callerHash = keccak256(abi.encodePacked(_authz.hashSalt, caller));
        bytes32[] memory targets = new bytes32[](3);
        targets[0] = keccak256(abi.encodePacked(_authz.hashSalt, address(this)));
        targets[1] = keccak256(abi.encodePacked(_authz.hashSalt, facet));
        targets[2] = keccak256(abi.encodePacked(_authz.hashSalt, funcSelector));
        uint256[] memory ops = new uint256[](1);
        ops[0] = AuthzLib.CALL_OP;
        uint256[] memory results = IAuthz(_authz.source)
            .authorize(
                domainHash,
                callerHash,
                targets,
                ops
            );
        for (uint256 i = 0; i < _authz.acceptedResults.length; i++) {
            for (uint256 j = 0; j < results.length; j++) {
                if (_authz.acceptedResults[i] == results[j]) {
                    return;
                }
            }
        }
        revert("DMND:NAUTH");
    }

    function __setAuthzSource(address authzSource) private {
        require(authzSource != address(0), "DMND:ZA");
        require(
            IERC165(authzSource).supportsInterface(type(IAuthz).interfaceId),
            "DMND:IAS"
        );
        _authz.source = authzSource;
    }

    function __setAppRegistry(address appRegistry) private {
        if (appRegistry != address(0)) {
            require(
                IERC165(appRegistry).supportsInterface(type(IAppRegistry).interfaceId),
                "DMND:IAR"
            );
        }
        _appRegistry = appRegistry;
        emit AppRegistrySet(_appRegistry);
    }

    function __installApp(
        string memory appName,
        string memory appVersion,
        bool deleteCurrentFacets
    ) private {
        require(_appRegistry != address(0), "DMND:ZAR");
        if (deleteCurrentFacets) {
            FacetManagerLib._deleteAllFacets();
        }
        address[] memory appFacets =
            IAppRegistry(_appRegistry).getAppFacets(appName, appVersion);
        for (uint256 i = 0; i < appFacets.length; i++) {
            FacetManagerLib._addFacet(appFacets[i]);
        }
        if (appFacets.length > 0) {
            emit AppInstall(_appRegistry, appName, appVersion);
        }
    }

    /* solhint-disable no-complex-fallback */
    fallback() external payable {
        require(_initialized, "DMND:NI");
        address facet = FacetManagerLib._findFacet(msg.sig);
        _authorizeCall(msg.sender, facet, msg.sig, false);
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