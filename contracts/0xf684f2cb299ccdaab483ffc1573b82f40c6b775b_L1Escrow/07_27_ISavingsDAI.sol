// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISavingsDAI {
  function deposit(uint256 assets, address receiver)
    external
    returns (uint256 shares);
  function previewDeposit(uint256 assets) external view returns (uint256);
  function previewRedeem(uint256 shares) external view returns (uint256);
  function redeem(uint256 shares, address receiver, address owner)
    external
    returns (uint256 assets);
  function withdraw(uint256 assets, address receiver, address owner)
    external
    returns (uint256 shares);
}