// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IMintFeeOracle {
  function fee(uint256 _projectId, uint256 _price) external view returns (uint256);

  function setFeeRate(uint256 _feeRate, uint256 _projectId) external;
}