// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISimpleRewardPool{
    function claimRewards(address,uint256,address,uint256) external returns(bool);
}