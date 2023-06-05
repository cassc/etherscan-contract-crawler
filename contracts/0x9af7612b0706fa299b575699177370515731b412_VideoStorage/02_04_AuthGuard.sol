// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "./Registry.sol";

contract AuthGuard {
    Registry internal registry;

    constructor(address _registry) {
        initializeAuthGuard(_registry);
    }

    function initializeAuthGuard(address _registry) public {
        if (registry == Registry(address(0))) {
            registry = Registry(_registry);
        }
    }

    function isAuthorized(
        address _user,
        address _operator,
        bytes4 _role
    ) public view returns (bool) {
        return registry.isAuthorized(_user, _operator, _role);
    }

    function isAuthorizedById(
        uint64 _id,
        bytes4 _role,
        address _operator
    ) public view returns (bool) {
        return registry.isAuthorizedById(_id, _operator, _role);
    }

    function contractPermissions(address _contract) public view returns (bool) {
        return registry.contractPermissions(_contract);
    }

    function getIdOwner(uint64 _id) public view returns (address) {
        return registry.getIdOwner(_id);
    }

    function getStorageContract(uint64 _id) public view returns (address) {
        return registry.getStorageContract(_id);
    }

    function getPlugin(uint64 _id) public view returns (address) {
        return registry.getPlugin(_id);
    }

    function connectPluginContract(uint64 _id) internal {
        return registry.connectPluginContract(_id);
    }

    function migratePluginContract(
        uint64 _id,
        address _newPluginContract
    ) external returns (bool) {
        return registry.migratePluginContract(_id, _newPluginContract);
    }

    function registerStorageContract(
        address _owner,
        uint8 _salt
    ) internal returns (uint64) {
        return registry.registerStorageContract(_owner, _salt);
    }

    function migrateStorageContract(
        uint64 _id,
        address _newStorageContract
    ) internal returns (bool) {
        return registry.migrateStorageContract(_id, _newStorageContract);
    }

    modifier onlyAdmin() {
        require(registry.isAdmin(msg.sender), "UNAUTHORIZED");
        _;
    }

    modifier onlyOperatorByUser(address _user) {
        require(
            registry.isAdmin(msg.sender) ||
                registry.isOperator(_user, msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier onlyAuthorizedByUser(address _user, bytes4 _role) {
        require(
            registry.isAuthorized(_user, msg.sender, _role),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier onlyAuthorizedById(uint64 _id, bytes4 _role) {
        require(
            registry.isAuthorizedById(_id, msg.sender, _role),
            "UNAUTHORIZED"
        );
        _;
    }

    modifier onlyWhitelistedContract() {
        require(
            registry.isAdmin(msg.sender) ||
                registry.contractPermissions(msg.sender),
            "UNAUTHORIZED"
        );
        _;
    }
}