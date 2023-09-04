// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../permissions/Pausable.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "../interfaces/IRegistryPermission.sol";

contract RegistryPermission is Initializable, OwnableUpgradeable, IRegistryPermission {
    address public permissionPerson;

    mapping(address => bool) public operatorRegisterPermission;
    mapping(address => bool) public operatorDeregisterPermission;
    mapping(address => bool) public dataStoreRollupPermission;
    mapping(address => bool) public delegatorPermission;


    event AddOperatorRegisterPermission(address operator, bool status);
    event AddOperatorDeregisterPermission(address operator, bool status);
    event AddDataStoreRollupPermission(address pusher, bool status);
    event AddDelegatorPermission(address delegator, bool status);
    event ChangeOperatorRegisterPermission(address operator, bool status);
    event ChangeOperatorDeregisterPermission(address operator, bool status);
    event ChangeDataStoreRollupPermission(address pusher, bool status);
    event ChangeDelegatorPermission(address delegator, bool status);

    constructor() {
        _disableInitializers();
    }

    modifier onlyPermissionPerson() {
        require(msg.sender == permissionPerson, "Only the permission person can do this action");
        _;
    }

    function initialize(address personAddress, address initialOwner) public initializer {
        permissionPerson = personAddress;
        _transferOwnership(initialOwner);
    }

    function addOperatorRegisterPermission(address operator) external onlyPermissionPerson {
        operatorRegisterPermission[operator] = true;
        emit AddOperatorRegisterPermission(operator, true);
    }

    function addOperatorDeregisterPermission(address operator) external onlyPermissionPerson {
        operatorDeregisterPermission[operator] = true;
        emit AddOperatorDeregisterPermission(operator, true);
    }

    function addDataStoreRollupPermission(address pusher) external onlyPermissionPerson {
        dataStoreRollupPermission[pusher] = true;
        emit AddDataStoreRollupPermission(pusher, true);
    }

    function addDelegatorPermission(address delegator) external onlyPermissionPerson {
        delegatorPermission[delegator] = true;
        emit AddDelegatorPermission(delegator, true);
    }

    function changeOperatorRegisterPermission(address operator, bool status) external onlyPermissionPerson {
        require(
            operatorRegisterPermission[operator] != status,
            "RegistryPermission.changeOperatorRegisterPermission: Status is same, don't need to change"
        );
        operatorRegisterPermission[operator] = status;
        emit ChangeOperatorRegisterPermission(operator, status);
    }

    function changeOperatorDeregisterPermission(address operator, bool status) external onlyPermissionPerson {
        require(
            operatorDeregisterPermission[operator] != status,
            "RegistryPermission.changeOperatorDeregisterPermission: Status is same, don't need to change"
        );
        operatorDeregisterPermission[operator] = status;
        emit ChangeOperatorDeregisterPermission(operator, status);
    }

    function changeDataStoreRollupPermission(address pusher, bool status) external onlyPermissionPerson {
        require(
            dataStoreRollupPermission[pusher] != status,
            "RegistryPermission.changeDataStoreRollupPermission: Status is same, don't need to change"
        );
        dataStoreRollupPermission[pusher] = status;
        emit ChangeDataStoreRollupPermission(pusher, status);
    }

    function changeDelegatorPermission(address delegator, bool status) external onlyPermissionPerson {
        require(
            delegatorPermission[delegator] != status,
            "RegistryPermission.changeDataStoreRollupPermission: Status is same, don't need to change"
        );
        delegatorPermission[delegator] = status;
        emit ChangeDelegatorPermission(delegator, status);
    }

    function getOperatorRegisterPermission(address operator) external view returns (bool) {
        return operatorRegisterPermission[operator];
    }

    function getOperatorDeregisterPermission(address operator) external view returns (bool) {
        return operatorDeregisterPermission[operator];
    }

    function getDataStoreRollupPermission(address pusher) external view returns (bool) {
        return dataStoreRollupPermission[pusher];
    }

    function getDelegatorPermission(address delegator) external view returns (bool) {
        return delegatorPermission[delegator];
    }

    function setPermissionPerson(address personAddress) external onlyOwner {
        require(
            personAddress != address(0),
            "RegistryPermission.changeDataStoreRollupPermission: personAddress is the zero address"
        );
        permissionPerson = personAddress;
    }
}