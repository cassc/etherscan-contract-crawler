// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

  interface IPropsFeeManager {
    function getFeeSetting() external view returns (uint256);
    function getETHWEIFeeSetting() external view returns (uint256);
    function getSplitSetting() external view returns (uint256);
    function getTipSplitSetting() external view returns (uint256);
    function getLatestPrice() external view returns (int);
    function getCurrentTotalFeeInETH() external view returns (uint256);
    function getCurrentCreatorFeeInETH() external view returns (uint256);
  }