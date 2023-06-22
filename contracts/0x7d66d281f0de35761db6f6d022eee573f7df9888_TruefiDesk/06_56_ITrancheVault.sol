// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title ITrancheVault
 * @author AlloyX
 */
interface ITrancheVault is IERC20Upgradeable {
  function totalAssets() external view returns (uint256);

  function convertToAssets(uint256 shares) external view returns (uint256);

  function deposit(uint256 amount, address receiver) external returns (uint256);

  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) external returns (uint256);
}