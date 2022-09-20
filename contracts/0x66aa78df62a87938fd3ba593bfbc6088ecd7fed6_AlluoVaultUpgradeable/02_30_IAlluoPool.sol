//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IAlluoPool {
    function farm() external;
    function withdraw(uint256 amount) external;
    function fundsLocked() external view returns (uint256);
    function claimRewardsFromPool() external;

}