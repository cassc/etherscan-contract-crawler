// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {IModuleMetadata} from "../bases/interfaces/IModuleMetadata.sol";

uint256 constant LATEST_VERSION = type(uint256).max;

contract UpgradeableModuleProxyFactory is Ownable {
    error ProxyAlreadyDeployedForNonce();
    error FailedInitialization();
    error ModuleVersionAlreadyRegistered();
    error UnexistentModuleVersion();

    event ModuleRegistered(IModuleMetadata indexed implementation, string moduleId, uint256 version);
    event ModuleProxyCreated(address indexed proxy, IModuleMetadata indexed implementation);

    mapping(string => mapping(uint256 => IModuleMetadata)) internal modules;
    mapping(string => uint256) public latestModuleVersion;

    function register(IModuleMetadata implementation) external onlyOwner {
        string memory moduleId = implementation.moduleId();
        uint256 version = implementation.moduleVersion();

        if (address(modules[moduleId][version]) != address(0)) {
            revert ModuleVersionAlreadyRegistered();
        }

        modules[moduleId][version] = implementation;

        if (version > latestModuleVersion[moduleId]) {
            latestModuleVersion[moduleId] = version;
        }

        emit ModuleRegistered(implementation, moduleId, version);
    }

    function getImplementation(string memory moduleId, uint256 version)
        public
        view
        returns (IModuleMetadata implementation)
    {
        if (version == LATEST_VERSION) {
            version = latestModuleVersion[moduleId];
        }
        implementation = modules[moduleId][version];
        if (address(implementation) == address(0)) {
            revert UnexistentModuleVersion();
        }
    }

    function deployUpgradeableModule(string memory moduleId, uint256 version, bytes memory initializer, uint256 salt)
        public
        returns (address proxy)
    {
        return deployUpgradeableModule(getImplementation(moduleId, version), initializer, salt);
    }

    function deployUpgradeableModule(IModuleMetadata implementation, bytes memory initializer, uint256 salt)
        public
        returns (address proxy)
    {
        proxy = createProxy(implementation, keccak256(abi.encodePacked(keccak256(initializer), salt)));

        (bool success,) = proxy.call(initializer);
        if (!success) {
            revert FailedInitialization();
        }
    }
    
    /**
     * @dev Proxy EVM code from factory/proxy-asm generated with ETK
     */
    function createProxy(IModuleMetadata implementation, bytes32 salt) internal returns (address proxy) {
        bytes memory initcode = abi.encodePacked(
            hex"73",
            implementation,
            hex"7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc55603b8060403d393df3363d3d3760393d3d3d3d3d363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4913d913e3d9257fd5bf3"
        );

        assembly {
            proxy := create2(0, add(initcode, 0x20), mload(initcode), salt)
        }

        if (proxy == address(0)) {
            revert ProxyAlreadyDeployedForNonce();
        }

        emit ModuleProxyCreated(proxy, implementation);
    }
}