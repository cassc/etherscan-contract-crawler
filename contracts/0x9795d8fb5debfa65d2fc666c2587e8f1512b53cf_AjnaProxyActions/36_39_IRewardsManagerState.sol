// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Rewards Manager State
 */
interface IRewardsManagerState {

    /**
     *  @notice Track whether a bucket's exchange rate has been updated in a given burn event epoch.
     *  @param  pool_        The pool to check the update status of.
     *  @param  bucketIndex_ The bucket index to check the update status of.
     *  @param  epoch_   The burn epoch to check the bucket index in.
     *  @return `True` if the buckets exchange rate was updated in the given epoch, else false.
     */
    function isBucketUpdated(
        address pool_,
        uint256 bucketIndex_,
        uint256 epoch_
    ) external view returns (bool);

    /**
     *  @notice Track whether a depositor has claimed rewards for a given burn event epoch.
     *  @param  tokenId_ ID of the staked `LP` `NFT`.
     *  @param  epoch_   The burn epoch to track if rewards were claimed.
     *  @return `True` if rewards were claimed for the given epoch, else false.
     */
    function isEpochClaimed(
        uint256 tokenId_,
        uint256 epoch_
    ) external view returns (bool);

    /**
     *  @notice Track the total amount of rewards that have been claimed for a given epoch.
     *  @param  epoch_   The burn epoch to track if rewards were claimed.
     *  @return The amount of rewards claimed in given epoch.
     */
    function rewardsClaimed(
        uint256 epoch_
    ) external view returns (uint256);

    /**
     *  @notice Track the total amount of rewards that have been claimed for a given burn event's bucket updates.
     *  @param  epoch_   The burn epoch to track if rewards were claimed.
     *  @return The amount of update rewards claimed in given epoch.
     */
    function updateRewardsClaimed(
        uint256 epoch_
    ) external view returns (uint256);

    /**
     *  @notice Retrieve information about a given stake.
     *  @param  tokenId_          `ID` of the `NFT` staked in the rewards contract to retrieve information about.
     *  @return owner_            The owner of a given `NFT` stake.
     *  @return pool_             The `Pool` the `NFT` represents positions in.
     *  @return lastClaimedEpoch_ The last burn epoch in which the owner of the `NFT` claimed rewards.
     */
    function getStakeInfo(
        uint256 tokenId_
    ) external view returns (address owner_, address pool_, uint256 lastClaimedEpoch_);

    /**
     *  @notice Retrieve information about recorded `LP` and rate values for a given bucket and a given stake, at stake time.
     *  @param  tokenId_  `ID` of the `NFT` staked in the rewards contract to retrieve information about.
     *  @param  bucketId_ `ID` of the bucket to retrieve recorded information at stake time.
     *  @return `LP` amount (in `WAD`) the `NFT` owner is entitled in current bucket at the time of staking.
     *  @return Current bucket exchange rate (`WAD`) at the time of staking.
     */
    function getBucketStateStakeInfo(
        uint256 tokenId_,
        uint256 bucketId_
    ) external view returns (uint256, uint256);

}

/*********************/
/*** State Structs ***/
/*********************/

/// @dev Struct holding stake info state.
struct StakeInfo {
    address ajnaPool;                         // address of the Ajna pool the NFT corresponds to
    uint96  lastClaimedEpoch;                 // last epoch the stake claimed rewards
    address owner;                            // owner of the LP NFT
    uint96  stakingEpoch;                     // epoch at staking time
    mapping(uint256 => BucketState) snapshot; // the LP NFT's balances and exchange rates in each bucket at the time of staking
}

/// @dev Struct holding bucket state at stake time.
struct BucketState {
    uint256 lpsAtStakeTime;  // [WAD] LP amount the NFT owner is entitled in current bucket at the time of staking
    uint256 rateAtStakeTime; // [WAD] current bucket exchange rate at the time of staking
}