// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ITreasuryExtension {
  function ETHValue(uint256 _projectId) external view returns (uint256);
}