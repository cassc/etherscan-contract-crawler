// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../staking/StakingCommons.sol";

interface ICafeStaking {
    /**
     * @dev Emitted when a track is created that will distribute `rewards` $CAFE to holders of `asset`.
     */
    event TrackCreated(
        uint256 indexed id,
        address indexed asset,
        uint256 indexed rps
    );

    /**
     * @dev Emitted when a track is toggled (paused or resumed).
     */
    event TrackToggled(uint256 indexed id, bool indexed newState);

    /**
     * @dev Emitted when a track's reward balance is replenished.
     *
     */
    event TrackReplenished(
        uint256 indexed id,
        uint256 indexed amount,
        uint256 indexed newRps
    );

    /**
     * @dev Emitted when a track's reward balance is reduced.
     *
     */
    event TrackReduced(
        uint256 indexed id,
        uint256 indexed amount,
        uint256 indexed newRps
    ); 

    /**
     * @dev Emitted when an asset is staked.
     */
    event AssetStaked(address indexed asset, address account, uint256 amount);

    /**
     * @dev Emitted when an asset is unstaked.
     */
    event AssetUnstaked(address indexed asset, address account, uint256 amount);

    /**
     * @dev Emitted when `reward` tokens are claimed by `account`.
     */
    event RewardPaid(address indexed account, uint256 indexed reward);

    function createTrack(
        address asset,
        uint256 rewardsAmount,
        TrackType atype,
        uint256 start,
        uint256 end,
        uint256 lower,
        uint256 upper,
        bool transferLock
    ) external;

    function replenishTrack(uint256 trackId, uint256 amount) external;

    function toggleTrack(uint256 trackId) external;

    function execute(
        StakeRequest[] calldata msr,
        StakeAction[][] calldata actions
    ) external;

    function execute4(
        address account,
        StakeRequest[] calldata msr,
        StakeAction[][] calldata actions
    ) external;

    function rewardPerToken(uint256 trackId) external view returns (uint256);

    function earned(uint256 trackId, address account)
        external
        view
        returns (uint256);
}