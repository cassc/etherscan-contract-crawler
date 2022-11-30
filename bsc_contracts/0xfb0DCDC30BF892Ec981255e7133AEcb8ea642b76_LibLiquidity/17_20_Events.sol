// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

contract Events {
    event UpdateSequence(uint32 sequence);

    //////////////////////////////////////////////////////////////////////////////////////
    //                                   trade
    struct OpenPositionArgs {
        bytes32 subAccountId;
        uint8 collateralId;
        bool isLong;
        uint96 amount;
        uint96 assetPrice;
        uint96 collateralPrice;
        uint96 newEntryPrice;
        uint96 feeUsd;
        uint96 remainPosition;
        uint96 remainCollateral;
    }
    event OpenPosition(address indexed trader, uint8 indexed assetId, OpenPositionArgs args);
    struct ClosePositionArgs {
        bytes32 subAccountId;
        uint8 collateralId;
        uint8 profitAssetId;
        bool isLong;
        uint96 amount;
        uint96 assetPrice;
        uint96 collateralPrice;
        uint96 profitAssetPrice;
        uint96 feeUsd;
        bool hasProfit;
        uint96 pnlUsd;
        uint96 remainPosition;
        uint96 remainCollateral;
    }
    event ClosePosition(address indexed trader, uint8 indexed assetId, ClosePositionArgs args);
    struct LiquidateArgs {
        bytes32 subAccountId;
        uint8 collateralId;
        uint8 profitAssetId;
        bool isLong;
        uint96 amount;
        uint96 assetPrice;
        uint96 collateralPrice;
        uint96 profitAssetPrice;
        uint96 feeUsd;
        bool hasProfit;
        uint96 pnlUsd;
        uint96 remainCollateral;
    }
    event Liquidate(address indexed trader, uint8 indexed assetId, LiquidateArgs args);
    struct WithdrawProfitArgs {
        bytes32 subAccountId;
        uint8 collateralId;
        uint8 profitAssetId;
        bool isLong;
        uint256 withdrawRawAmount;
        uint96 assetPrice;
        uint96 collateralPrice;
        uint96 profitAssetPrice;
        uint96 entryPrice;
        uint96 feeUsd;
    }
    event WithdrawProfit(address indexed trader, uint8 indexed assetId, WithdrawProfitArgs args);
    event CollectedFee(uint8 tokenId, uint96 fee);
    event ClaimBrokerGasRebate(address indexed receiver, uint32 transactions, uint256 rawAmount);

    //////////////////////////////////////////////////////////////////////////////////////
    //                                   liquidity
    event AddLiquidity(
        address indexed trader,
        uint8 indexed tokenId,
        uint96 tokenPrice,
        uint96 mlpPrice,
        uint96 mlpAmount,
        uint96 fee
    );
    event RemoveLiquidity(
        address indexed trader,
        uint8 indexed tokenId,
        uint96 tokenPrice,
        uint96 mlpPrice,
        uint96 mlpAmount,
        uint96 fee
    );
    event UpdateFundingRate(
        uint8 indexed tokenId,
        uint32 longFundingRate, // 1e5
        uint128 longCumulativeFundingRate, // Σ_t fundingRate_t
        uint32 shortFundingRate, // 1e5
        uint128 shortCumulativeFunding // Σ_t fundingRate_t * indexPrice_t
    );
    event IssueMuxToken(
        uint8 indexed tokenId, // if isStable, tokenId will always be 0
        bool isStable,
        uint96 muxTokenAmount
    );
    event RedeemMuxToken(address trader, uint8 tokenId, uint96 muxTokenAmount);
    event Rebalance(
        address indexed rebalancer,
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 price0,
        uint96 price1,
        uint96 rawAmount0,
        uint96 rawAmount1
    );

    //////////////////////////////////////////////////////////////////////////////////////
    //                                   admin
    event AddAsset(
        uint8 indexed id,
        bytes32 symbol,
        uint8 decimals,
        bool isStable,
        address tokenAddress,
        address muxTokenAddress
    );
    event SetAssetParams(
        uint8 indexed assetId,
        bytes32 symbol,
        uint32 newInitialMarginRate,
        uint32 newMaintenanceMarginRate,
        uint32 newPositionFeeRate,
        uint32 newLiquidationFeeRate,
        uint32 newMinProfitRate,
        uint32 newMinProfitTime,
        uint96 newMaxLongPositionSize,
        uint96 newMaxShortPositionSize,
        uint32 newSpotWeight,
        uint32 newHalfSpread
    );
    event SetAssetFlags(uint8 indexed assetId, uint56 oldFlags, uint56 newFlags);
    event SetReferenceOracle(
        uint8 indexed assetId,
        uint8 referenceOracleType,
        address referenceOracle,
        uint32 referenceDeviation
    );
    event SetFundingParams(uint8 indexed assetId, uint32 newBaseRate8H, uint32 newLimitRate8H);
    event SetFundingInterval(uint32 oldFundingInterval, uint32 newFundingInterval);
    event SetMlpPriceRange(uint96 newLowerBound, uint96 newUpperBound);
    event SetLiquidityFee(uint32 newLiquidityBaseFeeRate, uint32 newLiquidityDynamicFeeRate);
    event SetStrictStableDeviation(uint32 newStrictStableDeviation);
    event SetBrokerGasRebate(uint96 newBrokerGasRebate);
    event SetMaintainer(address indexed newMaintainer);
    event SetLiquidityManager(address indexed newLiquidityManager, bool isAdd);
    event WithdrawCollectedFee(uint8 indexed assetId, uint96 collectedFee);
    event TransferLiquidity(address indexed sender, address indexed recipient, uint8 assetId, uint256 amount);
    event BorrowAsset(
        uint8 indexed assetId,
        address indexed project,
        address indexed borrower,
        uint256 rawBorrowAmount,
        uint256 rawFee
    );
    event RepayAsset(
        uint8 indexed assetId,
        address indexed project,
        address indexed repayer,
        uint256 rawRepayAmount,
        uint256 rawFee,
        uint256 badDebt
    );
}