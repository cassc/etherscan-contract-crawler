// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Rewards Manager Owner Actions
 */
interface IRewardsManagerOwnerActions {

    /**
     *  @notice Claim `Ajna` token rewards that have accrued to a staked `LP` `NFT`.
     *  @dev    Updates exchange rates for each bucket the `NFT` is associated with.
     *  @dev    Reverts with `InsufficientLiquidity` if calculated rewards or contract balance is below specified min amount to receive limit.
     *  @param  tokenId_      `ID` of the staked `LP` `NFT`.
     *  @param  epochToClaim_ The burn epoch to claim rewards for.
     *  @param  minAmount_    Minimum amount to be received by rewards claimer.
     */
    function claimRewards(
        uint256 tokenId_,
        uint256 epochToClaim_,
        uint256 minAmount_
    ) external;

    /**
     *  @notice Stake a `LP` `NFT` into the rewards contract.
     *  @dev    Updates exchange rates for each bucket the `NFT` is associated with.
     *  @param  tokenId_ `ID` of the `LP` `NFT` to stake in the `Rewards contract.
     */
    function stake(
        uint256 tokenId_
    ) external;

    /**
     *  @notice Withdraw a staked `LP` `NFT` from the rewards contract.
     *  @notice If rewards are available, claim all available rewards before withdrawal.
     *  @param  tokenId_ `ID` of the staked `LP` `NFT`.
     */
    function unstake(
        uint256 tokenId_
    ) external;

    /**
     *  @notice Withdraw a staked `LP` `NFT` from the rewards contract without claiming any rewards before withdrawal.
     *  @param  tokenId_ `ID` of the staked `LP` `NFT`.
     */
    function emergencyUnstake(
        uint256 tokenId_
    ) external;

    /**
     *  @notice Update the exchange rate of a list of buckets.
     *  @dev    Caller can claim `5%` of the rewards that have accumulated to each bucket since the last burn event, if it hasn't already been updated.
     *  @param  pool_       Address of the pool whose exchange rates are being updated.
     *  @param  subsetHash_ Factory's subset hash pool that dpeloyed the Ajna pool. Used to validate that the `pool_` address is a legit Ajna pool.
     *  @param  indexes_    List of bucket indexes to be updated.
     *  @return Returns reward amount for updating bucket exchange rates.
     */
    function updateBucketExchangeRatesAndClaim(
        address pool_,
        bytes32 subsetHash_,
        uint256[] calldata indexes_
    ) external returns (uint256);

}