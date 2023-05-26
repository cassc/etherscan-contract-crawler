// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStakingReward {
    function willStakeTokens(address account, uint16[] calldata tokenIds) external;
    function willUnstakeTokens(address account, uint16[] calldata tokenIds) external;

    function willBeReplacedByContract(address stakingRewardContract) external;
    function didReplaceContract(address stakingRewardContract) external;
}