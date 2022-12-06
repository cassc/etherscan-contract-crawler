// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IAccessControlLight.sol";

contract AccessControlLight is IAccessControlLight {
  bytes32 internal constant ROLE_ADMIN = bytes32(uint256(0x00));
  bytes32 internal constant ROLE_SIGNER = bytes32(uint256(0x01));
  bytes32 internal constant ROLE_MINTER = bytes32(uint256(0x02));

  mapping(bytes32 => mapping(address => bool)) private _roles;

  address internal _owner;

  modifier onlyRole(bytes32 role) {
    _checkRole(role, msg.sender);
    _;
  }

  constructor() {
    emit OwnershipTransferred(_owner, msg.sender);
    emit RoleGranted(ROLE_ADMIN, msg.sender);
    _owner = msg.sender;
  }

  /**
   * @dev Returns `true` if `account` has been granted `role`.
     */
  function hasRole(bytes32 role, address account) public view virtual returns (bool) {
    if (role == ROLE_ADMIN && account == _owner) {
      return true;
    }
    return _roles[role][account];
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  function grantRole(bytes32 role, address account) public virtual onlyRole(ROLE_ADMIN) {
    _grantRole(role, account);
  }

  function revokeRole(bytes32 role, address account) public virtual onlyRole(ROLE_ADMIN) {
    _revokeRole(role, account);
  }

  function renounceRole(bytes32 role) public virtual {
    _revokeRole(role, msg.sender);
  }

  function transferOwnership(address newOwner) public virtual {
    if (msg.sender != _owner) {
      revert MissingRole();
    }
    if (newOwner == address(0)) {
      revert NeedAtLeastOneAdmin();
    }
    emit OwnershipTransferred(_owner, newOwner);
    emit RoleGranted(ROLE_ADMIN, newOwner);
    _owner = newOwner;
    if (hasRole(ROLE_ADMIN, msg.sender)) {
      _revokeRole(ROLE_ADMIN, msg.sender);
    }
  }

  function _checkRole(bytes32 role, address account) internal view virtual {
    if (!hasRole(role, account)) {
      revert MissingRole();
    }
  }

  function _grantRole(bytes32 role, address account) internal virtual {
    if (hasRole(role, account)) {
      revert NothingToDo();
    }
    _roles[role][account] = true;
    emit RoleGranted(role, account);
  }

  function _revokeRole(bytes32 role, address account) internal virtual {
    if (!hasRole(role, account)) {
      revert NothingToDo();
    }
    _roles[role][account] = false;
    emit RoleRevoked(role, account);
  }
}