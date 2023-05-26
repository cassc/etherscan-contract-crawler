// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Blacklist is Ownable {
  // wallet address => blacklisted status
  mapping(address => bool) public blacklist;

  event LogBlacklistAdded(address indexed account);
  event LogBlacklistRemoved(address indexed account);

  /**
    * @dev Add wallet to blacklist
    * `_account` must not be zero address
    */
  function addBlacklist(address[] calldata _accounts) external onlyOwner {
    for (uint256 i = 0; i < _accounts.length; i++) {
      blacklist[_accounts[i]] = true;

      emit LogBlacklistAdded(_accounts[i]);
    }
  }

  /**
    * @dev Remove wallet from blacklist
    */
  function removeBlacklist(address[] calldata _accounts) external onlyOwner {
    for (uint256 i = 0; i < _accounts.length; i++) {
      delete blacklist[_accounts[i]];

      emit LogBlacklistRemoved(_accounts[i]);
    }
  }
}