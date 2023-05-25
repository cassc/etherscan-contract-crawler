pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


import "@openzeppelin/contracts/utils/Context.sol";

abstract contract AccessControl is Context {
  bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant STATUS_CHANGER_ROLE = keccak256('STATUS_CHANGER_ROLE');

  string constant INVALID_PERMISSION = "005001";

  address private _admin;

  /// Mapping from address to role to boolean
  mapping(address => mapping(bytes32 => bool)) private _roles;

  modifier onlyRole(bytes32 role) {
    require(_roles[_msgSender()][role] == true, INVALID_PERMISSION);
    _;
  }

  modifier onlyAdmin() {
    require(_msgSender() == _admin, INVALID_PERMISSION);
    _;
  }

  /**
   * Assign role to the specific address
   */
  function _grantRole(address to, bytes32 role) internal {
    require(to != address(0), INVALID_PERMISSION);
    _roles[to][role] = true;
  }

  /**
   * Revoke role
   */
  function _revokeRole(address from, bytes32 role) internal {
    _roles[from][role] = false;
  }

  /**
   * Set admin
   */
  function _setAdmin(address to) internal {
    require(to != address(0), INVALID_PERMISSION);
    _admin = to;
  }
}