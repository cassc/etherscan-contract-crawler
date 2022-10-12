// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0 <0.9.0;

interface IStakingService {
    function unstake(uint128 amount) external;
    function unstakeTo(address to, uint128 amount) external;
    function stakeFrom(address owner, uint128 amount) external;
    function claimReward() external returns (uint256);
}