// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract Administered is AccessControl {
    bytes32 public constant ADMIN = keccak256("ADMIN");

    /// @dev Add `root` to the admin role as a member.
    constructor(address[] memory admins) {
        for (uint256 i = 0; i < admins.length; i++) {
            _grantRole(ADMIN, admins[i]);
        }
        _setRoleAdmin(ADMIN, DEFAULT_ADMIN_ROLE);
    }

    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "AUTH: ONLY_ADMIN");
        _;
    }

    /// @dev Return `true` if the account belongs to the admin role.
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Add an account to the admin role. Restricted to admins.
    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Remove oneself from the admin role.
    function renounceAdmin() public virtual {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}