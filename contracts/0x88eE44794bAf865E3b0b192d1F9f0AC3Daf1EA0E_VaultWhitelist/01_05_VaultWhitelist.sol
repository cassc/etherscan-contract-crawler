// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {Errors} from '../libraries/helpers/Errors.sol';
import {ILendingPoolAddressesProvider} from '../../interfaces/ILendingPoolAddressesProvider.sol';
import {Ownable} from '../../dependencies/openzeppelin/contracts/Ownable.sol';

/**
 * @title VaultWhitelist
 * @notice Whitelist feature of vault
 * @author Sturdy
 **/

contract VaultWhitelist is Ownable {
  // vault -> user -> enabled?
  mapping(address => mapping(address => bool)) public whitelistUser;
  // vault -> enabled count
  mapping(address => uint256) public whitelistUserCount;
  // vault -> contract address -> enabled?
  mapping(address => mapping(address => bool)) public whitelistContract;

  /**
   * @dev add an user to the whitelist
   * @param user address
   */
  function addAddressToWhitelistUser(address vault, address user) external payable onlyOwner {
    if (!whitelistUser[vault][user]) {
      whitelistUser[vault][user] = true;
      whitelistUserCount[vault]++;
    }
  }

  /**
   * @dev add users to the whitelist
   * @param users addresses
   */
  function addAddressesToWhitelistUser(address vault, address[] calldata users)
    external
    payable
    onlyOwner
  {
    uint256 count;
    uint256 length = users.length;

    for (uint256 i; i < length; ++i) {
      address user = users[i];

      if (!whitelistUser[vault][user]) {
        whitelistUser[vault][user] = true;
        count++;
      }
    }

    whitelistUserCount[vault] = whitelistUserCount[vault] + count;
  }

  /**
   * @dev remove an user from the whitelist
   * @param user address
   */
  function removeAddressFromWhitelistUser(address vault, address user) external payable onlyOwner {
    if (whitelistUser[vault][user]) {
      whitelistUser[vault][user] = false;
      whitelistUserCount[vault]--;
    }
  }

  /**
   * @dev remove users from the whitelist
   * @param users addresses
   */
  function removeAddressesFromWhitelistUser(address vault, address[] calldata users)
    external
    payable
    onlyOwner
  {
    uint256 count;
    uint256 length = users.length;

    for (uint256 i; i < length; ++i) {
      address user = users[i];

      if (whitelistUser[vault][user]) {
        whitelistUser[vault][user] = false;
        count++;
      }
    }

    whitelistUserCount[vault] = whitelistUserCount[vault] - count;
  }

  /**
   * @dev add a contract to the whitelist
   * @param sender address
   */
  function addAddressToWhitelistContract(address vault, address sender) external payable onlyOwner {
    if (!whitelistContract[vault][sender]) {
      whitelistContract[vault][sender] = true;
    }
  }

  /**
   * @dev remove a contract from the whitelist
   * @param sender address
   */
  function removeAddressFromWhitelistContract(address vault, address sender)
    external
    payable
    onlyOwner
  {
    if (whitelistContract[vault][sender]) {
      whitelistContract[vault][sender] = false;
    }
  }
}