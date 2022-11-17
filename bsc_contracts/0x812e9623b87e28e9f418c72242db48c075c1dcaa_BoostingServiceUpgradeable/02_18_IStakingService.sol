// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0 <0.9.0;

interface IStakingService {
    struct Staker {
        uint256 amount;
        uint128 initialRewardRate;
        uint128 reward;
        uint256 claimedReward;
    }
    function unstake(uint128 amount) external;
    function unstakeTo(address to, uint128 amount) external;
    function stakeFrom(address owner, uint128 amount) external;
    function claimReward() external returns (uint256);

    function stakers(address owner) external view returns (Staker memory staker);
    function stakeFor(address owner, uint128 amount) external;
    function unstakeWithAuthorization(
        address owner,
        uint128 amount,
        uint128 signedAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function claimWithAuthorization(
        address owner,
        uint128 nmxAmount,
        uint128 signedAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}