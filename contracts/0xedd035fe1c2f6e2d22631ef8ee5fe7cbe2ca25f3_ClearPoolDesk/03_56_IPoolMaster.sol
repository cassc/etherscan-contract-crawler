// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title IPoolMaster
 * @author AlloyX
 */
interface IPoolMaster is IERC20Upgradeable {
  function getCurrentExchangeRate() external view returns (uint256);

  function provide(uint256 usdcAmount) external;

  function redeem(uint256 tokenAmount) external;
}