// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IFeeTierStrate {
  function getMaxFee() external view returns(uint256);
  function getDepositFee() external view returns(uint256, uint256);
  function getTotalFee() external view returns(uint256, uint256);
  function getWithdrawFee() external view returns(uint256, uint256);
  function getAllTier() external view returns(uint256[] memory);
  function getTier(uint256 index) external view returns(address, string memory, uint256);
}