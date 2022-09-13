// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool is IERC20 {
  function recognizableLossesOf(address _owner) external view returns (uint256);

  function withdrawableFundsOf(address _owner) external view returns (uint256);

  function withdraw(uint256 amt) external;

  function deposit(uint256 amt) external;
}