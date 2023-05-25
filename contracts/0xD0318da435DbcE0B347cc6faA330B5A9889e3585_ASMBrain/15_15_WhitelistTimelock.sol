// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';

contract WhitelistTimelock is Ownable {
  mapping(address => uint256) public whitelistTimelock;
  uint256 public constant MIN_LOCK_DURATION = 1 days;
  uint256 public lockDuration = 1 days;

  event AddedToWhitelist(address indexed account);
  event RemovedFromWhitelist(address indexed account);
  event LockDurationUpdated(uint256 duration);

  modifier onlyWhitelisted() {
    require(
      isWhitelisted(msg.sender),
      'Address not whitelisted or in lock-up period.'
    );
    _;
  }

  function addToWhitelist(address _address) public onlyOwner {
    whitelistTimelock[_address] = block.timestamp + lockDuration;
    emit AddedToWhitelist(_address);
  }

  function removeFromWhitelist(address _address) public onlyOwner {
    whitelistTimelock[_address] = 0;
    emit RemovedFromWhitelist(_address);
  }

  function updateLockDuration(uint256 duration) public onlyOwner {
    require(
      duration >= MIN_LOCK_DURATION,
      'Duration should be longer than MIN_LOCK_DURATION.'
    );

    lockDuration = duration;
    emit LockDurationUpdated(duration);
  }

  function isWhitelisted(address _address) public view returns (bool) {
    return
      whitelistTimelock[_address] > 0 &&
      block.timestamp >= whitelistTimelock[_address];
  }
}