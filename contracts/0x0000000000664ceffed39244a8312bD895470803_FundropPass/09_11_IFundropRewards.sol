// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IFundropRewards {
    function getRewardsBalance(address _minter) external view returns (uint256);
    function claimRewards(address _minter, bytes memory _args) external;
}