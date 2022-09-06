// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract ShibaCardsAccessible is AccessControl {
  address private _owner;
  bytes32 public constant WHITELISTED = keccak256("WHITELISTED");

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _owner = _msgSender(); 
  }

  /**
  * @dev Returns the address of the current owner. Required to identify as the owner of the contract on some platforms like Opensea.
  */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
  * @dev Transfers ownership of the contract to a new account (`newOwner`).
  * Can only be called by the current owner.
  */
  function transferOwnership(address newOwner) public virtual onlyAdmin {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _owner = _msgSender(); 
  }

  /// @dev Restricted to members of the whitelisted or admin role.
  modifier onlyWhitelistedOrAdmin() {
    require(
      isWhitelisted(_msgSender()) || isAdmin(_msgSender()),
      "Restricted to whitelisted or admin"
    );
    _;
  }

  /// @dev Restricted to members of the whitelisted role.
  modifier onlyWhitelisted() {
    require(isWhitelisted(_msgSender()), "Restricted to whitelisted.");
    _;
  }

  /// @dev Return `true` if the account belongs to the whitelisted role.
  function isWhitelisted(address account) public view virtual returns (bool) {
    return hasRole(WHITELISTED, account);
  }

  /// @dev Restricted to members of the admin role.
  modifier onlyAdmin() {
    require(isAdmin(_msgSender()), "Restricted to admins.");
    _;
  }

  /// @dev Return `true` if the account belongs to the admin role.
  function isAdmin(address account) public view virtual returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }
}