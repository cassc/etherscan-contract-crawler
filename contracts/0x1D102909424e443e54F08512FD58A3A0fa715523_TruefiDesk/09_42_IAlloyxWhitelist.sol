// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title Alloyx Whitelist Interface
 * @author AlloyX
 */
interface IAlloyxWhitelist {
  /**
   * @notice Check whether user is whitelisted
   * @param _whitelistedAddress The address to whitelist.
   */
  function isUserWhitelisted(address _whitelistedAddress) external view returns (bool);
}