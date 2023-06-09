// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title ICToken
 * @author AlloyX
 */
interface ICToken is IERC20Upgradeable {
  function mint(uint256 depositAmount) external;

  function redeem(uint256 sharesAmount) external;

  function exchangeRateStored() external view returns (uint256);
}