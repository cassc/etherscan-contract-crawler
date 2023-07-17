// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IVoteStrategyToken {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function balanceOf(address voter) external view returns (uint256);
}