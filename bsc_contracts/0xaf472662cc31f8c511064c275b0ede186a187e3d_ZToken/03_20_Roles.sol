// SPDX-License-Identifier: PRIVATE
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Roles is
    Initializable,
    OwnableUpgradeable,
    AccessControlUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet _admins;
    EnumerableSetUpgradeable.AddressSet _managers;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    function initialize() public virtual initializer {
        __Ownable_init_unchained();
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        _admins.add(msg.sender);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Roles: restricted to admins");
        _;
    }

    modifier onlyAdminOrManager() {
        require(isAdmin(msg.sender) || isManager(msg.sender), "Roles: restricted to admins or managers");
        _;
    }

    function addAdmin(address account) external onlyOwner {
        grantRole(ADMIN_ROLE, account);
        _admins.add(account);
    }

    function removeAdmin(address account) external onlyOwner {
        require(
            account != msg.sender,
            "Roles: you can not delete the admin role from yourself"
        );

        revokeRole(ADMIN_ROLE, account);
        _admins.remove(account);
    }

    function addManager(address account) external onlyOwner {
        grantRole(MANAGER_ROLE, account);
        _managers.add(account);
    }

    function removeManager(address account) external onlyOwner {
        revokeRole(MANAGER_ROLE, account);
        _managers.remove(account);
    }

    function removeAllAdminsExceptOwner() external onlyOwner {
        for (uint i = 0; i < _admins.length(); i++) {
            if (_admins.at(i) != owner()) {
                revokeRole(ADMIN_ROLE, _admins.at(i));
                _admins.remove(_admins.at(i));
                i--;
            }
        }
    }

    function renounceAdmin() external onlyAdmin {
        if (msg.sender == owner()) {
            require(
                _admins.length() == 1,
                "Roles: it is impossible to give up admin rights while there are still admins"
            );
        }

        renounceRole(ADMIN_ROLE, msg.sender);
        _admins.remove(msg.sender);
    }

    function isAdmin(address account) public view returns (bool) {
        return hasRole(ADMIN_ROLE, account) && _admins.contains(account);
    }

    function isManager(address account) public view returns (bool) {
        return hasRole(MANAGER_ROLE, account) && _managers.contains(account);
    }
}