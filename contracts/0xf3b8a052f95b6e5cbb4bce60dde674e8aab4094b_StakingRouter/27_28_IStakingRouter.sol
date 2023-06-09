// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;


interface IStakingRouter {

    struct SplitStakeOptions {
        uint256[] amounts;
        address[] stakeTo;
    }

    function STAKING() external view returns (address);
    function STAKING_TOKEN() external view returns (address);
    function STAKING_POSITION_MANAGER() external view returns (address);

    function rewardBalance(uint256 tokenId) external view returns (uint256);
    function totalBalance(uint256 tokenId) external view returns (uint256);

    function stake(
        uint256 tokenAmount,
        uint32 stakingDuration,
        uint256 minMultiplier,
        address recipient,
        uint256 deadline
    ) external returns (uint256 tokenId);

    function lockStake(
        uint256 tokenAmount,
        uint32 stakingDuration,
        uint32 lockDuration,
        uint256 minMultiplier,
        address recipient,
        uint256 deadline
    ) external returns (uint256 tokenId);

    function splitStake(
        uint256 tokenId,
        SplitStakeOptions calldata options,
        uint256 deadline
    ) external returns (uint256[] memory tokenIds);

    function unstake(
        uint256 tokenId,
        uint256 stakeAmount,
        uint256 maxUnstakePenalty,
        address unstakeTo,
        address recipient,
        uint256 deadline
    ) external returns (uint256 newTokenId);
}