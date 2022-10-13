// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

abstract contract BaseEnv {
    error Zero();

    error StakeNotFinish();

    error StakeNotStart();

    error ExceedMax();

    error NotAdmin();

    error InvalidStakeTime(uint256 start, uint256 end);

    event Withdrawed(address indexed owner, uint256 amount);

    event Staked(address indexed owner, uint256 amount, uint256 stakedTotal);

    event StakeConfigUpdate(address stakeToken, uint256 startTime, uint256 endTime, uint256 period);
}