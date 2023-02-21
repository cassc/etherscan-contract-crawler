// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @dev used for handling ETH wrapping into WETH to be stored in smart contracts upon deposit,
/// ... and used to unwrap WETH into ETH to deliver when withdrawing from smart contracts
interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;
}