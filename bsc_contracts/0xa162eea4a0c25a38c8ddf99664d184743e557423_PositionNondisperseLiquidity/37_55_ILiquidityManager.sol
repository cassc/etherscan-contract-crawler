// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "../libraries/liquidity/Liquidity.sol";

interface ILiquidityManager {
    enum ModifyType {
        INCREASE,
        DECREASE
    }

    struct AddLiquidityParams {
        IMatchingEngineAMM pool;
        uint128 amountVirtual;
        uint32 indexedPipRange;
        bool isBase;
    }

    //------------------------------------------------------------------------------------------------------------------
    // FUNCTIONS
    //------------------------------------------------------------------------------------------------------------------

    struct LiquidityDetail {
        uint128 baseVirtual;
        uint128 quoteVirtual;
        uint128 liquidity;
        uint128 power;
        uint256 indexedPipRange;
        uint128 feeBasePending;
        uint128 feeQuotePending;
        IMatchingEngineAMM pool;
    }

    /// @dev get all data of nft
    /// @param tokens array of tokens
    /// @return list array of struct LiquidityDetail
    function getAllDataDetailTokens(uint256[] memory tokens)
        external
        view
        returns (LiquidityDetail[] memory);

    /// @notice get data of tokens
    /// @param tokenId the id of token
    /// @return liquidity the value liquidity
    /// @return indexedPipRange the index pip range of token
    /// @return feeGrowthBase checkpoint of fee base
    /// @return feeGrowthQuote checkpoint of fee quote
    /// @return pool the pool liquidity provide
    function concentratedLiquidity(uint256 tokenId)
        external
        view
        returns (
            uint128 liquidity,
            uint32 indexedPipRange,
            uint256 feeGrowthBase,
            uint256 feeGrowthQuote,
            IMatchingEngineAMM pool
        );

    /// @dev get data of nft
    /// @notice provide liquidity for pool
    /// @param params struct of AddLiquidityParams
    function addLiquidity(AddLiquidityParams calldata params) external payable;

    /// @dev get data of nft
    /// @notice provide liquidity for pool with recipient nft id
    /// @param params struct of AddLiquidityParams
    /// @param recipient address to receive nft
    function addLiquidityWithRecipient(
        AddLiquidityParams calldata params,
        address recipient
    ) external payable;

    /// @dev remove liquidity
    /// @notice remove liquidity of token id and transfer asset
    /// @param nftTokenId id of token
    function removeLiquidity(uint256 nftTokenId) external;

    /// @dev remove liquidity
    /// @notice increase liquidity
    /// @param nftTokenId id of token
    /// @param amountModify amount increase
    /// @param isBase amount is base or quote
    function increaseLiquidity(
        uint256 nftTokenId,
        uint128 amountModify,
        bool isBase
    ) external payable;

    /// @dev decrease liquidity and transfer asset
    /// @notice increase liquidity
    /// @param nftTokenId id of token
    /// @param liquidity amount decrease
    function decreaseLiquidity(uint256 nftTokenId, uint128 liquidity) external;

    /// @dev shiftRange to other index of range
    /// @notice increase liquidity
    /// @param nftTokenId id of token
    /// @param targetIndex target index shift to
    /// @param amountNeeded amount need more
    /// @param isBase amount need more is base or quote
    function shiftRange(
        uint256 nftTokenId,
        uint32 targetIndex,
        uint128 amountNeeded,
        bool isBase
    ) external payable;

    /// @dev collect fee reward and transfer asset
    /// @notice collect fee reward
    /// @param nftTokenId id of token
    function collectFee(uint256 nftTokenId) external;

    /// @notice get liquidity detail of token id
    /// @param baseVirtual base amount with impairment loss
    /// @param quoteVirtual quote amount with impairment loss
    /// @param liquidity the amount of liquidity
    /// @param indexedPipRange index pip range provide liquidity
    /// @param feeBasePending amount fee base pending to collect
    /// @param feeQuotePending amount fee quote pending to collect
    /// @param pool provide liquidity
    function liquidity(uint256 nftTokenId)
        external
        view
        returns (
            uint128 baseVirtual,
            uint128 quoteVirtual,
            uint128 liquidity,
            uint128 power,
            uint256 indexedPipRange,
            uint128 feeBasePending,
            uint128 feeQuotePending,
            IMatchingEngineAMM pool
        );

    //------------------------------------------------------------------------------------------------------------------
    // EVENTS
    //------------------------------------------------------------------------------------------------------------------

    event LiquidityAdded(
        address indexed user,
        address indexed pool,
        uint256 indexed nftId,
        uint256 amountBaseAdded,
        uint256 amountQuoteAdded,
        uint64 indexedPipRange,
        uint256 addedLiquidity
    );

    event LiquidityRemoved(
        address indexed user,
        address indexed pool,
        uint256 indexed nftId,
        uint256 amountBaseRemoved,
        uint256 amountQuoteRemoved,
        uint64 indexedPipRange,
        uint128 removedLiquidity
    );

    event LiquidityModified(
        address indexed user,
        address indexed pool,
        uint256 indexed nftId,
        uint256 amountBaseModified,
        uint256 amountQuoteModified,
        // 0: increase
        // 1: decrease
        ModifyType modifyType,
        uint64 indexedPipRange,
        uint128 modifiedLiquidity
    );

    event LiquidityShiftRange(
        address indexed user,
        address indexed pool,
        uint256 indexed nftId,
        uint64 oldIndexedPipRange,
        uint128 liquidityRemoved,
        uint256 amountBaseRemoved,
        uint256 amountQuoteRemoved,
        uint64 newIndexedPipRange,
        uint128 newLiquidity,
        uint256 amountBaseAdded,
        uint256 amountQuoteAded
    );
}