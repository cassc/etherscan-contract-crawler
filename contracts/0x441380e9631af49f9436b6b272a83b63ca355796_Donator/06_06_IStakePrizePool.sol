// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IStakePrizePool {
    function withdrawInstantlyFrom(address from, uint256 amount, address controlledToken, uint256 maximumExitFee) external returns (uint256);
}