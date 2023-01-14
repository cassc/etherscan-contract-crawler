// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';

contract VaultControl is AccessControlEnumerableUpgradeable {
    bytes32 private constant _OPERATOR_ROLE = keccak256('OPERATOR');
    bytes32 private constant _CONTROLLER_ROLE = keccak256('CONTROLLER');

    function _VaultControl_Init(address account) internal onlyInitializing {
        __AccessControl_init();
        _setRoleAdmin(_OPERATOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(_CONTROLLER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, account);
        _setupRole(_OPERATOR_ROLE, account);
        _setupRole(_CONTROLLER_ROLE, account);
    }

    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), 'Restricted to Admins.');
        _;
    }

    /// @dev Restricted to members of the Controller role.
    modifier onlyController() {
        require(isController(_msgSender()), 'Restricted to Controllers.');
        _;
    }

    /// @dev Restricted to members of the Operator role.
    modifier onlyOperator() {
        require(isOperator(_msgSender()), 'Restricted to Operators.');
        _;
    }

    /// @dev Return `true` if the account belongs to the admin role.
    function isAdmin(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Add an account to the admin role. Restricted to admins.
    function addAdmin(address account) public onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Return `true` if the account belongs to the operator role.
    function isOperator(address account) public view returns (bool) {
        return hasRole(_OPERATOR_ROLE, account);
    }

    /// @dev Add an account to the operator role. Restricted to admins.
    function addOperator(address account) external onlyAdmin {
        grantRole(_OPERATOR_ROLE, account);
    }

    /// @dev Remove an account from the Operator role. Restricted to admins.
    function removeOperator(address account) external onlyAdmin {
        revokeRole(_OPERATOR_ROLE, account);
    }

    /// @dev Return `true` if the account belongs to the Controller role.
    function isController(address account) public view returns (bool) {
        return hasRole(_CONTROLLER_ROLE, account);
    }

    /// @dev Add an account to the Controller role. Restricted to admins.
    function addController(address account) external onlyAdmin {
        grantRole(_CONTROLLER_ROLE, account);
    }

    /// @dev Remove an account from the Controller role. Restricted to Admins.
    function removeController(address account) external onlyAdmin {
        revokeRole(_CONTROLLER_ROLE, account);
    }

    /// @dev Remove oneself from the Admin role thus all other roles.
    function renounceAdmin() external {
        address sender = _msgSender();
        renounceRole(DEFAULT_ADMIN_ROLE, sender);
        renounceRole(_OPERATOR_ROLE, sender);
        renounceRole(_CONTROLLER_ROLE, sender);
    }

    /// @dev Remove oneself from the Operator role.
    function renounceOperator() external {
        renounceRole(_OPERATOR_ROLE, _msgSender());
    }

    /// @dev Remove oneself from the Controller role.
    function renounceController() external {
        renounceRole(_CONTROLLER_ROLE, _msgSender());
    }

    uint256[50] private __gap;
}