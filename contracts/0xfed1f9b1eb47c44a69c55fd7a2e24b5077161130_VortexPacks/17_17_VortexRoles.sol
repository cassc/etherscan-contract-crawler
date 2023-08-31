// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Simplification of AccessControl to save gas.
 */
abstract contract VortexRoles is Ownable {
    mapping(address => uint256) private _roles;

    function grantRole(uint256 role, address account) external onlyOwner {
        _grantRole(role, account);
    }

    function revokeRole(uint256 role, address account) external onlyOwner {
        _revokeRole(role, account);
    }

    function hasRole(uint256 role, address account) public view returns (bool) {
        return _roles[account] & role == role;
    }

    function _grantRole(uint256 role, address account) internal {
        unchecked {
            _roles[account] |= role;
        }
    }

    function _revokeRole(uint256 role, address account) internal {
        unchecked {
            _roles[account] &= ~role;
        }
    }
}