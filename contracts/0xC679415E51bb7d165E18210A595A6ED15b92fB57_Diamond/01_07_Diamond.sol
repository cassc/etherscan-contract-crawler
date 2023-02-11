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

import "../authz/IAuthz.sol";
import "../app-registry/IAppRegistry.sol";
import "./IDiamond.sol";
import "./IDiamondFacet.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
contract Diamond is IDiamond {

    // authoization settings
    bool private _authzFrozen;
    address private _authzSource;
    string private _authzDomain;
    uint256[] private _acceptedAuthzResults;
    string private _authzHashSalt;

    string private _detailsURI;
    bytes4[] private _defaultSupportingInterfceIds;
    bool private _diamondFrozen;
    address[] private _facets;
    mapping(address => uint256) private _facetArrayIndex;
    mapping(address => bool) private _deletedFacets;
    mapping(bytes4 => address) private _selectorToFacetMap;
    mapping(bytes4 => bool) private _protectedSelectorMap;
    mapping(address => bool) private _frozenFacets;

    string[] private _overridenFuncSigs;
    mapping(string => uint256) private _overridenFuncSigsIndex;

    address private _appRegistry;

    string private _name;

    event FacetAdd(address facet);
    event FacetDelete(address facet);
    event AppInstall(address appRegistry, string name, string version);
    event FuncSigOverride(string funcSig, address facet);
    event ProtectFuncSig(string funcSig, bool protect);
    event FreezeDiamond();

    event FreezeAuthz();

    event AppRegistrySet(address appRegistry);

    modifier notFrozenDiamond {
        require(!_diamondFrozen, "DMND:DFRZN");
        _;
    }

    modifier notFrozenAuthz {
        require(!_authzFrozen, "DMND:AFRZN");
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
        string memory name,
        address appRegistry,
        address authzSource,
        string memory authzDomain,
        bytes4[] memory defaultSupportingInterfceIds
    ) {
        _diamondFrozen = false;
        _authzFrozen = false;
        _name = name;
        _defaultSupportingInterfceIds = defaultSupportingInterfceIds;
        __setAppRegistry(appRegistry);
        __setAuthzSource(authzSource);
        _authzDomain = authzDomain;
        _authzHashSalt = "Dwt2wb1d976h";
        _acceptedAuthzResults.push(AuthzLib.ACCEPT_ACTION);
    }

    function supportsInterface(bytes4 interfaceId)
      public view override getterAuthz virtual returns (bool) {
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
        for (uint256 i = 0; i < _defaultSupportingInterfceIds.length; i++) {
            if (interfaceId == _defaultSupportingInterfceIds[i]) {
                return true;
            }
        }
        return false;
    }

    function getDiamondName() external view virtual override getterAuthz returns (string memory) {
        return _name;
    }

    function getDiamondVersion() external view virtual override getterAuthz  returns (string memory) {
        return "2.3.0";
    }

    function setDiamondName(string memory name) external mutatorAuthz {
        _name = name;
    }

    function getDetailsURI() external view getterAuthz returns (string memory) {
        return _detailsURI;
    }

    function setDetailsURI(string memory detailsURI) external mutatorAuthz {
        _detailsURI = detailsURI;
    }


    function getAuthzSource() external view getterAuthz returns (address) {
        return _authzSource;
    }

    function setAuthzSource(address authzSource) external notFrozenAuthz mutatorAuthz {
        __setAuthzSource(authzSource);
    }

    function getAuthzDomain() external view getterAuthz returns (string memory) {
        return _authzDomain;
    }

    function setAuthzDomain(string memory authzDomain) external notFrozenAuthz mutatorAuthz {
        require(bytes(authzDomain).length > 0, "DMND:ED");
        _authzDomain = authzDomain;
    }

    function getAcceptedAuthzResults() external view getterAuthz returns (uint256[] memory) {
        return _acceptedAuthzResults;
    }

    function setAcceptedAuthzResults(
        uint256[] memory acceptedAuthzResults
    ) external notFrozenAuthz mutatorAuthz {
        require(acceptedAuthzResults.length > 0, "DMND:EA");
        _acceptedAuthzResults = acceptedAuthzResults;
    }

    function getAppRegistry() external view getterAuthz returns (address) {
        return _appRegistry;
    }

    function setAppRegistry(address appRegistry) external notFrozenDiamond mutatorAuthz {
        __setAppRegistry(appRegistry);
    }

    function isDiamondFrozen() external view getterAuthz returns (bool) {
        return _diamondFrozen;
    }

    function freezeDiamond() external notFrozenDiamond mutatorAuthz {
        _diamondFrozen = true;
        emit FreezeDiamond();
    }

    function isAuthzFrozen() external view getterAuthz returns (bool) {
        return _authzFrozen;
    }

    function freezeAuthz() external notFrozenAuthz mutatorAuthz {
        _authzFrozen = true;
        emit FreezeAuthz();
    }

    function isFacetFrozen(address facet) external view getterAuthz returns (bool) {
        return _frozenFacets[facet];
    }

    function freezeFacet(address facet) external mutatorAuthz {
        require(facet != address(0), "DMND:ZF");
        require(!_frozenFacets[facet], "DMND:FAF");
        _frozenFacets[facet] = true;
    }

    function getFacets() external view override getterAuthz returns (address[] memory) {
        return __getFacets();
    }

    function resolve(string[] memory funcSigs) external view getterAuthz returns (address[] memory) {
        return __resolve(funcSigs);
    }

    function areFuncSigsProtected(
        string[] memory funcSigs
    ) external view getterAuthz returns (bool[] memory) {
        bool[] memory results = new bool[](funcSigs.length);
        for (uint256 i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            bytes4 selector = __getSelector(funcSig);
            results[i] = _protectedSelectorMap[selector];
        }
        return results;
    }

    function protectFuncSig(string memory funcSig, bool protect) external notFrozenAuthz mutatorAuthz {
        __protectFuncSig(funcSig, protect);
    }

    function addFacets(address[] memory facets) external notFrozenDiamond mutatorAuthz {
        require(facets.length > 0, "DMND:ZL");
        for (uint256 i = 0; i < facets.length; i++) {
            __addFacet(facets[i]);
        }
    }

    function deleteFacets(address[] memory facets) external notFrozenDiamond mutatorAuthz {
        require(facets.length > 0, "DMND:ZL");
        for (uint256 i = 0; i < facets.length; i++) {
            __deleteFacet(facets[i]);
        }
    }

    function deleteAllFacets() external notFrozenDiamond mutatorAuthz {
        for (uint256 i = 0; i < _facets.length; i++) {
            __deleteFacet(_facets[i]);
        }
    }

    function installApp(
        string memory appName,
        string memory appVersion,
        bool deleteCurrentFacets
    ) external notFrozenDiamond mutatorAuthz {
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

    // WARN: Never use this function directly. The proper way is to add a facet as a whole.
    function overrideFuncSigs(
        string[] memory funcSigs,
        address[] memory facets
    ) external notFrozenDiamond mutatorAuthz {
        __overrideFuncSigs(funcSigs, facets);
    }

    function getOverridenFuncSigs() external view getterAuthz returns (string[] memory) {
        return _overridenFuncSigs;
    }

    function tryAuthorizeCall(
        address caller,
        string memory funcSig
    ) external view getterAuthz {
        address facet = _findFacet(msg.sig);
        bytes4 funcSelector = __getSelector(funcSig);
        _authorizeCall(caller, facet, funcSelector, false);
    }

    function _findFacet(bytes4 selector) internal view returns (address) {
        address facet = _selectorToFacetMap[selector];
        require(facet != address(0), "DMND:FNF");
        require(!_deletedFacets[facet], "DMND:FREM");
        return facet;
    }

    function _authorizeCall(
        address caller,
        address facet,
        bytes4 funcSelector,
        bool treatAsProtected
    ) internal view {
        if (!treatAsProtected && !_protectedSelectorMap[funcSelector]) {
            return;
        }
        require(_authzSource != address(0), "DMND:ZA");
        bytes32 domainHash = keccak256(abi.encodePacked(_authzHashSalt, _authzDomain));
        bytes32 callerHash = keccak256(abi.encodePacked(_authzHashSalt, caller));
        bytes32[] memory targets = new bytes32[](3);
        targets[0] = keccak256(abi.encodePacked(_authzHashSalt, address(this)));
        targets[1] = keccak256(abi.encodePacked(_authzHashSalt, facet));
        targets[2] = keccak256(abi.encodePacked(_authzHashSalt, funcSelector));
        uint256[] memory ops = new uint256[](1);
        ops[0] = AuthzLib.CALL_OP;
        uint256[] memory results = IAuthz(_authzSource)
            .authorize(
                domainHash,
                callerHash,
                targets,
                ops
            );
        for (uint256 i = 0; i < _acceptedAuthzResults.length; i++) {
            for (uint256 j = 0; j < results.length; j++) {
                if (_acceptedAuthzResults[i] == results[j]) {
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
        _authzSource = authzSource;
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
        require(facet != address(0), "DMND:ZF");
        require(
            IDiamondFacet(facet).supportsInterface(type(IDiamondFacet).interfaceId),
            "DMND:IF"
        );
        string[] memory funcSigs = IDiamondFacet(facet).getFacetPI();
        for (uint256 i = 0; i < funcSigs.length; i++) {
            string memory funcSig = funcSigs[i];
            bytes4 selector = __getSelector(funcSig);
            address currentFacet = _selectorToFacetMap[selector];
            if (currentFacet != address(0)) {
                // current facet must not be frozen
                require(!_frozenFacets[currentFacet], "DMND:FF");
            }
            _selectorToFacetMap[selector] = facet;
            __protectFuncSig(funcSig, false);
        }
        string[] memory protectedFuncSigs = IDiamondFacet(facet).getFacetProtectedPI();
        for (uint256 i = 0; i < protectedFuncSigs.length; i++) {
            string memory protectedFuncSig = protectedFuncSigs[i];
            __protectFuncSig(protectedFuncSig, true);
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
        require(!_frozenFacets[facet], "DMND:FF");
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
            address currentFacet = _selectorToFacetMap[selector];
            if (currentFacet != address(0)) {
                // current facet must not be frozen
                require(!_frozenFacets[currentFacet], "DMND:FF");
            }
            _selectorToFacetMap[selector] = facet;
            _deletedFacets[facet] = false;
            if (_overridenFuncSigsIndex[funcSig] == 0) {
                _overridenFuncSigs.push(funcSig);
                _overridenFuncSigsIndex[funcSig] = _overridenFuncSigs.length;
            }
            emit FuncSigOverride(funcSig, facet);
        }
    }

    function __protectFuncSig(string memory funcSig, bool protect) private {
        bytes4 selector = __getSelector(funcSig);
        bool oldValue = _protectedSelectorMap[selector];
        _protectedSelectorMap[selector] = protect;
        if (oldValue != protect) {
            emit ProtectFuncSig(funcSig, protect);
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

    /* solhint-disable no-complex-fallback */
    fallback() external payable {
        address facet = _findFacet(msg.sig);
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