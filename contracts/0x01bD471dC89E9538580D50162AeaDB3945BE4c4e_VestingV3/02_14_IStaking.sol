//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IStaking {
    function unstakeExtend(address _staker) external;

    function getStakerDetails(address _staker)
        external
        view
        returns (
            uint256 amountStaked,
            uint256 availableReward,
            uint128 unstakeTime,
            uint128 lastUpdateTime,
            uint256 claimTime
        );
}