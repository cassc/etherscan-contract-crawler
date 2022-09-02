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

import "../app-registry/IAppRegistry.sol";
import "../security/task-executor/TaskExecutorBase.sol";
import "../security/task-executor/TaskExecutorLib.sol";
import "../security/role-manager/RoleManagerBase.sol";
import "../security/role-manager/RoleManagerLib.sol";
import "./IDiamond.sol";
import "./IDiamondFacet.sol";
import "./DiamondConfig.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract Diamond is
  IDiamond,
  TaskExecutorBase,
  RoleManagerBase
{
    event FacetAdd(address facet);
    event FacetDelete(address facet);
    event Freeze();
    event AppInstall(address appRegistry, string name, string version);
    event AppRegistrySet(address appRegistry);
    event FuncSigOverride(string funcSig, address facet);

    string private _name;
    address private _appRegistry;
    bool internal _frozen;
    address[] internal _facets;
    mapping(address => uint256) private _facetArrayIndex;
    mapping(address => bool) private _deletedFacets;
    mapping(bytes4 => address) private _selectorToFacetMap;

    modifier onlyDiamondAdmin() {
        RoleManagerLib._checkRole(DiamondConfig.ROLE_DIAMOND_ADMIN);
        _;
    }

    constructor(
        address taskManager,
        address[] memory diamondAdmins,
        string memory name,
        address appRegistry
    ) {
        // The diamond is not frozen by default.
        _frozen = false;
        TaskExecutorLib._setTaskManager(taskManager);
        for(uint i = 0; i < diamondAdmins.length; i++) {
            RoleManagerLib._grantRole(diamondAdmins[i], DiamondConfig.ROLE_DIAMOND_ADMIN);
        }
        _name = name;
        _appRegistry = appRegistry;
        emit AppRegistrySet(_appRegistry);
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
        return "1.1.0";
    }

    function getAppRegistry() external view onlyDiamondAdmin returns (address) {
        return _appRegistry;
    }

    function setAppRegistry(address appRegistry) external onlyDiamondAdmin {
        require(!_frozen, "DMND:FRZN");
        if (appRegistry != address(0)) {
            require(
                IERC165(appRegistry).supportsInterface(type(IAppRegistry).interfaceId),
                "DMND:IAR"
            );
        }
        _appRegistry = appRegistry;
        emit AppRegistrySet(_appRegistry);
    }

    function isFrozen() external view returns (bool) {
        return _frozen;
    }

    function freeze() external onlyDiamondAdmin {
        require(!_frozen, "DMND:FRZN");
        _frozen = true;
        emit Freeze();
    }

    function getFacets() external view override onlyDiamondAdmin returns (address[] memory) {
        return __getFacets();
    }

    function addFacets(address[] memory facets) external onlyDiamondAdmin {
        require(!_frozen, "DMND:FRZN");
        require(facets.length > 0, "DMND:ZL");
        for (uint256 i = 0; i < facets.length; i++) {
            __addFacet(facets[i]);
        }
    }

    function deleteFacets(address[] memory facets) external onlyDiamondAdmin {
        require(!_frozen, "DMND:FRZN");
        require(facets.length > 0, "DMND:ZL");
        for (uint256 i = 0; i < facets.length; i++) {
            __deleteFacet(facets[i]);
        }
    }

    function deleteAllFacets() external onlyDiamondAdmin {
        require(!_frozen, "DMND:FRZN");
        for (uint256 i = 0; i < _facets.length; i++) {
            __deleteFacet(_facets[i]);
        }
    }

    function installApp(
        string memory appName,
        string memory appVersion,
        bool deleteCurrentFacets
    ) external onlyDiamondAdmin {
        require(!_frozen, "DMND:FRZN");
        require(_appRegistry != address(0), "DMND:ZAR");
        if (deleteCurrentFacets) {
            for (uint256 i = 0; i < _facets.length; i++) {
                __deleteFacet(_facets[i]);
            }
        }
        address[] memory appFacets =
            IAppRegistry(_appRegistry).getAppFacets(appName, appVersion);
        for (uint256 i = 0; i < appFacets.length; i++) {
            __addFacet(appFacets[i]);
        }
        if (appFacets.length > 0) {
            emit AppInstall(_appRegistry, appName, appVersion);
        }
    }

    // WARN: Never use this function directly. The proper way is to add a facet
    //       as a whole.
    function overrideFuncSigs(
        string[] memory funcSigs,
        address[] memory facets
    ) external onlyDiamondAdmin {
        require(!_frozen, "DMND:FRZN");
        __overrideFuncSigs(funcSigs, facets);
    }

    function _findFacet(bytes4 selector) internal view returns (address) {
        address facet = _selectorToFacetMap[selector];
        require(facet != address(0), "DMND:FNF");
        require(!_deletedFacets[facet], "DMND:FREM");
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

    function __addFacet(address facet) private {
        require(facet != address(0), "DMND:ZF");
        require(
            IDiamondFacet(facet).supportsInterface(type(IDiamondFacet).interfaceId),
            "DMND:IF"
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
        require(facet != address(0), "DMND:ZF");
        _deletedFacets[facet] = true;
        emit FacetDelete(facet);
    }

    function __overrideFuncSigs(
        string[] memory funcSigs,
        address[] memory facets
    ) private {
        require(funcSigs.length > 0, "DMND:ZL");
        require(funcSigs.length == facets.length, "DMND:IL");
        for (uint i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            address facet = facets[i];
            bytes4 selector = __getSelector(funcSig);
            _selectorToFacetMap[selector] = facet;
            // WARN: Undeleting an already deleted facet may result in unwanted
            //       consequences. Make sure to set address(0) for all other
            //       function signatures in such facet.
            _deletedFacets[facet] = false;
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
                revert("DMND:IFS");
            }
        }
        return bytes4(keccak256(bytes(funcSig)));
    }
}