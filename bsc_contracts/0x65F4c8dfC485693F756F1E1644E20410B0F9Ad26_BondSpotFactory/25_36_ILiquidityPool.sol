// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../spot-exchange/libraries/liquidity/PoolLiquidity.sol";
import "../spot-exchange/libraries/liquidity/LiquidityInfo.sol";

interface ILiquidityPool {
    event LiquidityAdded(
        bytes32 indexed poolKey,
        address indexed user,
        uint128 baseAmount,
        uint128 quoteAmount,
        uint128 totalQValue
    );

    event LiquidityRemoved(
        bytes32 indexed poolKey,
        address indexed user,
        uint256 tokenId,
        uint128 baseAmount,
        uint128 quoteAmount,
        uint128 totalQValue,
        int128 pnl
    );

    event PoolAdded(bytes32 indexed poolKey, address executer);

    event SpotFactoryAdded(address oldFactory, address newFactory);

    struct AddLiquidityParams {
        bytes32 poolId;
        // gridType see {Grid.GridType}
        //        uint8 gridType;
        // pip lower limit
        //        uint80 lowerLimit;
        // pip upper limit
        //        uint80 upperLimit;
        // grid count
        //        uint16 gridCount;
        uint128 baseAmount;
        uint128 quoteAmount;
    }

    struct ReBalanceState {
        int128 soRemovablePosBuy;
        int128 soRemovablePosSell;
        uint256 claimableQuote;
        uint256 claimableBase;
        uint256 feeQuoteAmount;
        uint256 feeBaseAmount;
        IPairManager pairManager;
        bytes32 poolId;
    }

    /// @notice Add liquidity to the pool
    /// @dev Add token0, token1 to the pool and return an ERC721 token representing the liquidity
    function addLiquidity(AddLiquidityParams calldata params) external;

    /// @notice Remove liquidity from the pool
    /// @dev Explain to a developer any extra details
    function removeLiquidity(uint256 tokenId) external;

    /// @notice Resupply the pool based on pool strategy
    /// @dev Claim the unclaim amounts then re-supply the liquidity following the pool strategy
    /// caller receives a reward by calling this method
    function rebalance(bytes32 poolId) external;

    /// @notice Propose to change the rebalance strategy
    /// Note: to change rebalance strategy require votes from lp supplier
    function changeRebalanceStrategy() external;

    // @dev get the current PnL of a pool
    // @return Current profit and losses of the pool
    function getPoolPnL(bytes32 poolKey) external view returns (int128);

    // get pendingReward of an NFT
    // @param tokenId the nft token id
    // @return the total reward of the NFT in quote currency
    function pendingReward(uint256 tokenId)
        external
        view
        returns (uint256 rewardInQuote);

    //    function getPoolClaimable(
    //        bytes32 poolKey,
    //        PoolLiquidity.PoolLiquidityInfo memory data
    //    )
    //        external
    //        view
    //        returns (
    //            uint256 quote,
    //            uint256 base,
    //            uint256 feeQuoteAmount,
    //            uint256 feeBaseAmount
    //        );

    // @dev get the current pool liquidity
    // @param poolKey pool hash of the pool
    // @return quote amount,  base amount
    function getPoolLiquidity(bytes32 poolKey)
        external
        view
        returns (uint128 quote, uint128 base);

    // @dev get liquidity info of an NFT
    // get the total deposited of an NFT
    // @return PoolLiquidity.PoolLiquidityInfo
    //    function liquidityInfo(uint256 tokenId) external view returns (LiquidityInfo.Data memory);

    // @dev get the current poolInfo
    // @return PoolLiquidity.PoolLiquidityInfo
    //    function poolInfo(bytes32 poolKey) external view returns (PoolLiquidity.PoolLiquidityInfo memory);

    // @dev get data of nft
    function getDataNonfungibleToken(uint256 tokenId)
        external
        view
        returns (LiquidityInfo.Data memory);

    // @dev get all data of nft
    function getAllDataTokens(uint256[] memory tokens)
        external
        view
        returns (LiquidityInfo.Data[] memory);

    function receiveQuoteAndBase(
        bytes32 poolId,
        uint128 base,
        uint128 quote
    ) external;
}