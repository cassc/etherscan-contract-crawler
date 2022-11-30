// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IRibbonThetaYearnVault is IERC20Upgradeable {
  function deposit(uint256 amount) external;

  function withdrawInstantly(uint256 amount) external;

  function initiateWithdraw(uint256 numShares) external;

  function completeWithdraw() external;

  function stake(uint256 numShares) external;

  function accountVaultBalance(address account) external view returns (uint256);
}