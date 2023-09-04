// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Rewards Manager Events
 */
interface IRewardsManagerEvents {

     /**
     *  @notice Emitted when lender claims rewards that have accrued to their staked `NFT`.
     *  @param  owner         Owner of the staked `NFT`.
     *  @param  ajnaPool      Address of the `Ajna` pool the `NFT` corresponds to.
     *  @param  tokenId       `ID` of the staked `NFT`.
     *  @param  epochsClaimed Array of burn epochs claimed.
     *  @param  amount        The amount of `Ajna` tokens claimed by the staker.
     */
    event ClaimRewards(
        address indexed owner,
        address indexed ajnaPool,
        uint256 indexed tokenId,
        uint256[] epochsClaimed,
        uint256 amount
    );

     /**
     *  @notice Emitted when moves liquidity in a staked `NFT` between buckets.
     *  @param  tokenId     `ID` of the staked `NFT`.
     *  @param  fromIndexes Array of indexes from which liquidity was moved.
     *  @param  toIndexes   Array of indexes to which liquidity was moved.
     */
    event MoveStakedLiquidity(
        uint256 tokenId,
        uint256[] fromIndexes,
        uint256[] toIndexes
    );

    /**
     *  @notice Emitted when lender stakes their `LP` `NFT` in the rewards contract.
     *  @param  owner    Owner of the staked `NFT`.
     *  @param  ajnaPool Address of the `Ajna` pool the `NFT` corresponds to.
     *  @param  tokenId  `ID` of the staked `NFT`.
     */
    event Stake(
        address indexed owner,
        address indexed ajnaPool,
        uint256 indexed tokenId
    );

    /**
     *  @notice Emitted when someone records the latest exchange rate for a bucket in a pool, and claims the associated reward.
     *  @param  caller          Address of the recorder. The address which will receive an update reward, if applicable.
     *  @param  ajnaPool        Address of the `Ajna` pool whose exchange rates are being updated.
     *  @param  indexesUpdated  Array of bucket indexes whose exchange rates are being updated.
     *  @param  rewardsClaimed  Amount of `Ajna` tokens claimed by the recorder as a reward for updating each bucket index.
     */
    event UpdateExchangeRates(
        address indexed caller,
        address indexed ajnaPool,
        uint256[] indexesUpdated,
        uint256 rewardsClaimed
    );

    /**
     *  @notice Emitted when lender withdraws their `LP` `NFT` from the rewards contract.
     *  @param  owner    Owner of the staked `NFT`.
     *  @param  ajnaPool Address of the `Ajna` pool the `NFT` corresponds to.
     *  @param  tokenId  `ID` of the staked `NFT`.
     */
    event Unstake(
        address indexed owner,
        address indexed ajnaPool,
        uint256 indexed tokenId
    );
}