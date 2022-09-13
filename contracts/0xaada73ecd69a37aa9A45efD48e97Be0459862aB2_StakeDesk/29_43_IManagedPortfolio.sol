// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IManagedPortfolio is IERC20Upgradeable {
  function value() external view returns (uint256);

  function deposit(uint256 amount, bytes memory metadata) external;

  function withdraw(uint256 amount, bytes memory metadata)
    external
    returns (uint256 withdrawnAmount);
}