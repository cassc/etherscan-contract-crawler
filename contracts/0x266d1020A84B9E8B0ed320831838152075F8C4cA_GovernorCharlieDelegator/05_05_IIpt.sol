// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IIpt {
  function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);
}