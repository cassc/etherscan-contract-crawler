// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AccessRoleCommon.sol";

contract ProxyAccessCommon is AccessRoleCommon, AccessControl {
    modifier onlyOwner() {
        require(isAdmin(msg.sender) || isProxyAdmin(msg.sender), "Accessible: Caller is not an admin");
        _;
    }

    modifier onlyProxyOwner() {
        require(isProxyAdmin(msg.sender), "Accessible: Caller is not an proxy admin");
        _;
    }

    modifier onlyPolicyOwner() {
        require(isPolicy(msg.sender), "Accessible: Caller is not an policy admin");
        _;
    }

    function addProxyAdmin(address _owner)
        external
        onlyProxyOwner
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    function removeProxyAdmin()
        public virtual onlyProxyOwner
    {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function transferProxyAdmin(address newAdmin)
        external virtual
        onlyProxyOwner
    {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /// @dev add admin
    /// @param account  address to add
    function addAdmin(address account) public virtual onlyProxyOwner {
        grantRole(ADMIN_ROLE, account);
    }

    /// @dev remove admin
    function removeAdmin() public virtual onlyOwner {
        renounceRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev transfer admin
    /// @param newAdmin new admin address
    function transferAdmin(address newAdmin) external virtual onlyOwner {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(ADMIN_ROLE, newAdmin);
        renounceRole(ADMIN_ROLE, msg.sender);
    }

    function addPolicy(address _account) public virtual onlyProxyOwner {
        grantRole(POLICY_ROLE, _account);
    }

    function removePolicy() public virtual onlyPolicyOwner {
        renounceRole(POLICY_ROLE, msg.sender);
    }

    function deletePolicy(address _account) public virtual onlyProxyOwner {
        revokeRole(POLICY_ROLE, _account);
    }

    /// @dev whether admin
    /// @param account  address to check
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    function isProxyAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isPolicy(address account) public view virtual returns (bool) {
        return hasRole(POLICY_ROLE, account);
    }
}