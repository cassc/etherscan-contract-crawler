// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IBondModel {

    function gain(uint256 total_, uint256 loanable_, uint256 dailyRate_, uint256 principal_, uint16 forDays_) external pure returns (uint256);

    function maxDailyRate(uint256 total_, uint256 loanable_, uint256 dailyRate_) external pure returns (uint256);

}