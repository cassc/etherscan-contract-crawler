// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IFeeManager {

  error SplitsAreActive();

  error WithdrawFailed();

  function setFees(uint256 _fee, uint256 _commissionBPS) external;

  function calculateFees(uint256 salePrice, uint256 quantity) external view returns (uint256 fee, uint256 commission);

  function recipient() external view returns (address);

}