// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IsfrxETH is IERC20 {
  function pricePerShare() external view returns (uint256);

  function deposit(uint256 assets, address receiver) external returns (uint256 shares);

  function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
}