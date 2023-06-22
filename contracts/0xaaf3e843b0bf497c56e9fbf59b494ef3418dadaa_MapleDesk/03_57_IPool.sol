// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IPool
 * @author AlloyX
 */
interface IPool is IERC20 {
  function convertToExitAssets(uint256 shares_) external view returns (uint256 assets_);

  function redeem(
    uint256 shares_,
    address receiver_,
    address owner_
  ) external returns (uint256 assets_);

  function deposit(uint256 assets_, address receiver_) external returns (uint256 shares_);

  function decimals() external view returns (uint8);

  function requestRedeem(uint256 shares_, address owner_) external returns (uint256 escrowedShares_);
}