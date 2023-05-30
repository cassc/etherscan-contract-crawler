// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IVaultWhitelist {
  function whitelistUser(address vault, address user) external view returns (bool);

  function whitelistUserCount(address vault) external view returns (uint256);

  function whitelistContract(address vault, address sender) external view returns (bool);
}