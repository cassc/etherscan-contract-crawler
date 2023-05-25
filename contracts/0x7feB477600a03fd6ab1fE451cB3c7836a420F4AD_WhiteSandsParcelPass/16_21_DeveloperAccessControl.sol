// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Contract module that allows children to implement developer access control until the contract is locked.
 *
 * Once the contract is locked, any method protected by the {onlyUnlocked} modifier will only be accessible by any
 * address with the {DEFAULT_ADMIN_ROLE} (by default the contract owner).
 */
abstract contract DeveloperAccessControl is Context, Ownable {
  /** @dev The address of the wallet with the developer role. */
  address public developer;

  /** @dev If {locked} is {true}, only an address with the {DEFAULT_ADMIN_ROLE} can access protected methods. */
  bool public locked = false;

  constructor(address owner) {
    transferOwnership(owner);
    developer = _msgSender();
  }

  function setLocked() internal {
    locked = true;
  }

  function maybeLock() internal {
    if (!locked) {
      locked = true;
    }
  }

  modifier onlyUnlocked() {
    if (_msgSender() != owner()) {
      require(!locked, "DeveloperAccessControl: developer access is locked");
      require(_msgSender() == developer, "DeveloperAccessControl: missing required access");
    }

    _;
  }
}