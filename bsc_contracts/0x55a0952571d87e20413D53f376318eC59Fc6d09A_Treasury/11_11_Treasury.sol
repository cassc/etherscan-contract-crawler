// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Treasury is AccessControlUpgradeable {
    event BalanceAdded(uint256);
    event BalanceWithdrawn(address, uint256);
    address erc20;

    /*
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    */

    function initialize(address erc20_) public initializer {
        __AccessControl_init();
        erc20 = erc20_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addAdmin(address admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function removeAdmin(address admin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function withdraw(address to_, uint256 amount_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20(erc20).transfer(to_, amount_);
    }

    function isAdmin(address sender_) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, sender_);
    }

    function getErc20Address() public view returns (address) {
        return erc20;
    }
}