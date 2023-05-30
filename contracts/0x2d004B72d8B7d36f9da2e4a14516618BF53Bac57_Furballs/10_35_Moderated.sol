// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Moderated
/// @author LFG Gaming LLC
/// @notice Administration & moderation permissions utilities
abstract contract Moderated is Ownable {
  mapping (address => bool) public admins;
  mapping (address => bool) public moderators;

  function setAdmin(address addr, bool set) external onlyOwner {
    require(addr != address(0));
    admins[addr] = set;
  }

  /// @notice Moderated ownables may not be renounced (only transferred)
  function renounceOwnership() public override onlyOwner {
    require(false, 'OWN');
  }

  function setModerator(address mod, bool set) external onlyAdmin {
    require(mod != address(0));
    moderators[mod] = set;
  }

  function isAdmin(address addr) public virtual view returns(bool) {
    return owner() == addr || admins[addr];
  }

  function isModerator(address addr) public virtual view returns(bool) {
    return isAdmin(addr) || moderators[addr];
  }

  modifier onlyModerators() {
    require(isModerator(msg.sender), 'MOD');
    _;
  }

  modifier onlyAdmin() {
    require(isAdmin(msg.sender), 'ADMIN');
    _;
  }
}