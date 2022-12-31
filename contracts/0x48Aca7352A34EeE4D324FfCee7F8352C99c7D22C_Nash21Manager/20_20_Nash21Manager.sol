// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../lib/Contracts.sol";
import "../interfaces/INash21Manager.sol";

/// @title The Nash21 manager contract
/// @notice Handles the configuration of Nash21 ecosystem
/// @dev Controls addresses, IDs, deployments, upgrades, proxies, access control and pausability
contract Nash21Manager is INash21Manager, AccessControlUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @inheritdoc INash21Manager
    mapping(bytes32 => address) public get;

    /// @inheritdoc INash21Manager
    mapping(address => bytes32) public name;

    /// @inheritdoc INash21Manager
    mapping(bytes32 => bool) public locked;

    /// @inheritdoc INash21Manager
    mapping(address => address) public implementationByProxy;

    modifier checkLocked(bytes32 id) {
        require(!locked[id], "Nash21Manager: id locked");
        _;
    }

    constructor() initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, address(this));
        _setupRole(UPGRADER_ROLE, address(this));
    }

    /// @inheritdoc INash21Manager
    function setId(bytes32 id, address addr)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        checkLocked(id)
    {
        get[id] = addr;
        name[addr] = id;

        emit NewId(id, addr);
    }

    /// @inheritdoc INash21Manager
    function deployProxyWithImplementation(
        bytes32 id,
        address implementation,
        bytes memory initializeCalldata
    ) public onlyRole(DEFAULT_ADMIN_ROLE) checkLocked(id) {
        _deployProxy(id, implementation, initializeCalldata);

        emit Deployment(id, get[id], implementation, false);
    }

    /// @inheritdoc INash21Manager
    function deploy(
        bytes32 id,
        bytes memory bytecode,
        bytes memory initializeCalldata
    )
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        checkLocked(id)
        returns (address implementation)
    {
        implementation = Contracts.deploy(bytecode);

        address proxyAddress = get[id];

        if (proxyAddress != address(0)) {
            upgrade(id, implementation, initializeCalldata);
            emit Deployment(id, get[id], implementation, true);
        } else {
            _deployProxy(id, implementation, initializeCalldata);
            emit Deployment(id, get[id], implementation, false);
        }
    }

    /// @inheritdoc INash21Manager
    function upgrade(
        bytes32 id,
        address implementation,
        bytes memory initializeCalldata
    ) public onlyRole(DEFAULT_ADMIN_ROLE) checkLocked(id) {
        UUPSUpgradeable proxy = UUPSUpgradeable(payable(get[id]));
        if (initializeCalldata.length > 0) {
            proxy.upgradeToAndCall(implementation, initializeCalldata);
        } else {
            proxy.upgradeTo(implementation);
        }
        implementationByProxy[address(proxy)] = implementation;
    }

    function _deployProxy(
        bytes32 id,
        address implementation,
        bytes memory initializeCalldata
    ) private {
        address proxy = address(
            new ERC1967Proxy(implementation, initializeCalldata)
        );
        get[id] = proxy;
        name[proxy] = id;
        implementationByProxy[proxy] = implementation;
    }

    /// @inheritdoc INash21Manager
    function lock(bytes32 id) public onlyRole(DEFAULT_ADMIN_ROLE) {
        locked[id] = true;
        emit Locked(id, get[id]);
    }
}