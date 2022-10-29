// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IVaultWrapper {
  function previewWithdrawUnderlyingFromVault(
    address vault,
    uint256 shares
  ) external view returns (uint256 assetsVault, uint256 assetsPool);
}