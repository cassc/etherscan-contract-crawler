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
  mapping(address => mapping(address => bool)) public whitelist;
  // vault -> enabled count
  mapping(address => uint256) public whitelistCount;

  /**
   * @dev add an user to the whitelist
   * @param user address
   */
  function addAddressToWhitelist(address vault, address user) external payable onlyOwner {
    if (!whitelist[vault][user]) {
      whitelist[vault][user] = true;
      whitelistCount[vault]++;
    }
  }

  /**
   * @dev add users to the whitelist
   * @param users addresses
   */
  function addAddressesToWhitelist(address vault, address[] calldata users)
    external
    payable
    onlyOwner
  {
    uint256 count;
    uint256 length = users.length;

    for (uint256 i; i < length; ++i) {
      address user = users[i];

      if (!whitelist[vault][user]) {
        whitelist[vault][user] = true;
        count++;
      }
    }

    whitelistCount[vault] = whitelistCount[vault] + count;
  }

  /**
   * @dev remove an user from the whitelist
   * @param user address
   */
  function removeAddressFromWhitelist(address vault, address user) external payable onlyOwner {
    if (whitelist[vault][user]) {
      whitelist[vault][user] = false;
      whitelistCount[vault]--;
    }
  }

  /**
   * @dev remove users from the whitelist
   * @param users addresses
   */
  function removeAddressesFromWhitelist(address vault, address[] calldata users)
    external
    payable
    onlyOwner
  {
    uint256 count;
    uint256 length = users.length;

    for (uint256 i; i < length; ++i) {
      address user = users[i];

      if (whitelist[vault][user]) {
        whitelist[vault][user] = false;
        count++;
      }
    }

    whitelistCount[vault] = whitelistCount[vault] - count;
  }
}