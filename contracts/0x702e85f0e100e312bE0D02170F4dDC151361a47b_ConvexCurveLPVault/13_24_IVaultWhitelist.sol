// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IVaultWhitelist {
  function whitelist(address vault, address user) external view returns (bool);

  function whitelistCount(address vault) external view returns (uint256);
}