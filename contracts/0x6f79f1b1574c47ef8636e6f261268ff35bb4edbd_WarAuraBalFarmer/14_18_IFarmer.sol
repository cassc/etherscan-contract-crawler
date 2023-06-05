// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;

interface IFarmer {
  // the index stored by the farmer represents all the recevied tokens
  function getCurrentIndex() external view returns (uint256);
  function sendTokens(address receiver, uint256 amount) external;
  function stake(address token, uint256 amount) external;
  function token() external view returns (address);
}