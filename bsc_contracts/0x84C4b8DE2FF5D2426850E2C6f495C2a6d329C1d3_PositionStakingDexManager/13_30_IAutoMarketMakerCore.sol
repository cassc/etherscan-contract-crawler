/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "../libraries/amm/Liquidity.sol";
import "./IGetFeeShareAMM.sol";

interface IAutoMarketMakerCore {
    struct AddLiquidity {
        uint128 baseAmount;
        uint128 quoteAmount;
        uint32 indexedPipRange;
    }

    /// @notice Add liquidity and mint the NFT
    /// @param params Struct AddLiquidity
    /// @dev Depends on data struct with base amount, quote amount and index pip
    /// calculate the liquidity and increase liquidity at index pip
    /// @return baseAmountAdded the base amount will be added
    /// @return quoteAmountAdded the quote amount will be added
    /// @return liquidity calculate from quote and base amount
    /// @return feeGrowthBase tracking growth base
    /// @return feeGrowthQuote tracking growth quote
    function addLiquidity(
        AddLiquidity calldata params
    )
        external
        returns (
            uint128 baseAmountAdded,
            uint128 quoteAmountAdded,
            uint256 liquidity,
            uint256 feeGrowthBase,
            uint256 feeGrowthQuote
        );

    /// @notice the struct for remove liquidity avoid deep stack
    struct RemoveLiquidity {
        uint128 liquidity;
        uint32 indexedPipRange;
        uint256 feeGrowthBase;
        uint256 feeGrowthQuote;
    }

    /// @notice Remove liquidity in index pip of nft
    /// @param params Struct Remove liquidity
    /// @dev remove liquidity at index pip and decrease the data of liquidity info
    /// @return baseAmount base amount receive
    /// @return quoteAmount quote amount receive
    function removeLiquidity(
        RemoveLiquidity calldata params
    ) external returns (uint128 baseAmount, uint128 quoteAmount);

    /// @notice estimate amount receive when remove liquidity in index pip
    /// @param params struct Remove liquidity
    /// @dev calculate amount of quote and base
    /// @return baseAmount base amount receive
    /// @return quoteAmount quote amount receive
    /// @return liquidityInfo newest of liquidity info
    function estimateRemoveLiquidity(
        RemoveLiquidity calldata params
    )
        external
        view
        returns (
            uint128 baseAmount,
            uint128 quoteAmount,
            Liquidity.Info memory liquidityInfo
        );

    /// @notice get liquidity info of any index pip range
    /// @param index want to get info
    /// @dev load data from storage and return
    /// @return sqrtMaxPip sqrt of max pip
    /// @return sqrtMinPip sqrt of min pip
    /// @return quoteReal quote real of liquidity of index
    /// @return baseReal base real of liquidity of index
    /// @return indexedPipRange index of liquidity info
    /// @return feeGrowthBase the growth of base
    /// @return feeGrowthQuote the growth of base
    /// @return sqrtK sqrt of k=quoteReal*baseReal,
    function liquidityInfo(
        uint256 index
    )
        external
        view
        returns (
            uint128 sqrtMaxPip,
            uint128 sqrtMinPip,
            uint128 quoteReal,
            uint128 baseReal,
            uint32 indexedPipRange,
            uint256 feeGrowthBase,
            uint256 feeGrowthQuote,
            uint128 sqrtK
        );

    /// @notice get current index pip range
    /// @dev load current index pip range from storage
    /// @return The current pip range
    function pipRange() external view returns (uint128);

    /// @notice get the tick space for external generate orderbook
    /// @dev load current tick space from storage
    /// @return the config tick space
    function tickSpace() external view returns (uint32);

    /// @notice get current index pip range
    /// @dev load current current index pip range from storage
    /// @return the current index pip range
    function currentIndexedPipRange() external view returns (uint256);

    /// @notice get percent fee will be share when market order fill
    /// @dev load config fee from storage
    /// @return the config fee
    function feeShareAmm() external view returns (uint32);

    /// @notice get spot factory
    /// @return the config fee
    function spotFactory() external view returns (IGetFeeShareAMM);
}