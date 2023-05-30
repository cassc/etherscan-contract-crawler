// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;
 
 
 interface IPolkaBank {
     
     function bankDeposit(uint256 usdcAmount) external;
     
     function bankWithdraw() external;
 }