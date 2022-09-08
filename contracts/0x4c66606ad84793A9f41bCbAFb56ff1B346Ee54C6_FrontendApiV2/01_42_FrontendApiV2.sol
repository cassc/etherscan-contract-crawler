//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "../exchange41/ExchangeLedger.sol";
import "../exchange41/IncentivesHook.sol";
import "../exchange41/SpotMarketAmm.sol";
import "../incentives/ExternalLiquidityIncentives.sol";
import "../incentives/StakingIncentives.sol";
import "../token/LiquidityToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title The API for Futureswap's frontends.
/// This contract enables frontend applications to make a single request to the blockchain for multiple values.
contract FrontendApiV2 is GitCommitHash {
    // @dev Sets a limit to the number of iterations that we do in for-loops, to avoid having an
    // unbounded execution.
    uint256 constant MAX_ITERATIONS = 1000;

    struct ExchangeData {
        Token assetToken;
        Token stableToken;
        // These will be sorted in the same order as the external AMM pool.
        // For example, for a ETH-USDC Uniswap pool, the list would be [ETH, USDC].
        address[] tokens;
        uint256 indexPrice;
        uint256 markPrice;
        Liquidity liquidity;
        // Requested user's current position in the exchange.
        Position position;
        ExchangeConfig exchangeConfig;
        // Information about the incentives for liquidity providers participating in the exchange,
        // and the claimable and vested incentives for the requested user.
        IncentivesData liquidityProviderIncentives;
        IncentivesData externalLiquidityIncentives;
        IncentivesData[] openInterestIncentives;
        IncentivesData[] tradingFeeIncentives;
        // Current total open long/short positions in the exchange.
        int256 longPositionAsset;
        int256 shortPositionAsset;
    }

    struct Liquidity {
        // The liquidity token of the exchange
        Token liquidityToken;
        // The amount of asset available in the exchange as liquidity
        uint256 exchangeAssetAmount;
        // The amount of stable available in the exchange as liquidity
        uint256 exchangeStableAmount;
        // The amount of asset that the requested account could redeem for their liquidity token
        uint256 userAssetAmount;
        // The amount of stable that the requested account could redeem for their liquidity token
        uint256 userStableAmount;
        // The maximum amount of liquidity tokens that can be redeemed right now
        uint256 redeemableAmount;
        // A pending withdraw request that the requested account might have
        WithdrawRequest withdrawRequest;
    }

    struct WithdrawRequest {
        // The amount that the requested account is withdrawing
        uint256 amount;
        // The timestamp when the withdraw can be completed
        uint256 timestamp;
    }

    struct Position {
        // The amount of asset that the requested account owns / is in debt for
        int256 asset;
        // The amount of asset that the requested account owns / is in debt for
        int256 stable;
        // The trancheId of the position
        uint32 trancheId;
    }

    struct Token {
        // The address of the token
        address tokenAddress;
        // The balance that the account has
        uint256 userBalance;
        // The total supply of the token
        uint256 totalSupply;
        // The decimals of the token
        uint8 decimals;
        // The symbol of the token
        string symbol;
    }

    /// @dev Documentation for the fields can be found at `IExchangeLedger.ExchangeState`.
    struct ExchangeConfig {
        uint256 tradeFee;
        uint256 timeFee;
        uint256 maxLeverage;
        uint256 minCollateral;
        uint256 dfrRate;
        uint256 removeLiquidityFee;
        IExchangeLedger.ExchangeState exchangeState;
    }

    struct RewardsVesting {
        uint256 rewardAmount;
        uint256 availableTimestamp;
    }

    struct IncentivesData {
        uint256 distribution;
        uint256 claimable;
        RewardsVesting[] vesting;
    }

    /// @notice Returns an array of ExchangeData for a given exchange and user account.
    /// @param exchanges The array of exchanges to query
    /// @param externalLiquidityIncentives The array of `ExternalLiquidityIncentive` contracts, associated to each of
    /// the exchanges (mapping one to one, meaning that `_externalLiquidityIncentives[i]` corresponds to
    /// `_exchanges[i]`). Zero address should be used when a particular exchange has not external liquidity incentives.
    /// @param account The account to query data for on each exchange.
    /// @param time The time to query data for on each exchange. We need the time to compute DFR and time fee.
    function getExchangeData(
        address[] calldata exchanges,
        address[] calldata externalLiquidityIncentives,
        address account,
        uint256 time
    ) external view returns (ExchangeData[] memory) {
        ExchangeData[] memory exchangeDataArray = new ExchangeData[](exchanges.length);

        for (uint256 i = 0; i < exchanges.length; i++) {
            computeExchangeData(
                exchanges[i],
                externalLiquidityIncentives[i],
                account,
                exchangeDataArray[i],
                time
            );
        }

        return exchangeDataArray;
    }

    function computeExchangeData(
        address exchangeAddress,
        address externalLiquidityIncentivesAddress,
        address user,
        ExchangeData memory exchangeData,
        uint256 time
    ) private view {
        ExchangeLedger exchangeLedger = ExchangeLedger(exchangeAddress);
        SpotMarketAmm amm = SpotMarketAmm(payable(address(exchangeLedger.amm())));
        IncentivesHook incentivesHook = IncentivesHook(address(exchangeLedger.hook()));

        populatePriceData(exchangeData, amm);
        populateTokenData(exchangeData, amm, user);
        populateLiquidityTokenData(exchangeData.liquidity, amm, user);
        populateLiquidityData(exchangeData.liquidity, amm, user);
        populateLiquidityIncentivesData(exchangeData, amm, user);
        populateExchangeConfigAndState(exchangeData, exchangeLedger, amm);
        populateOpenInterestData(exchangeData, exchangeLedger);
        populateUserPositionData(exchangeData, exchangeLedger, user, time);
        populateTradeIncentivesData(exchangeData, incentivesHook, user);
        populateExternalIncentivesData(exchangeData, externalLiquidityIncentivesAddress, user);
    }

    function populatePriceData(ExchangeData memory exchangeData, SpotMarketAmm amm) private view {
        int256 assetPrice = amm.oracle().getPrice(amm.assetToken());
        exchangeData.indexPrice = FsMath.safeCastToUnsigned(assetPrice);
        exchangeData.markPrice = FsMath.safeCastToUnsigned(amm.getAssetPrice());
    }

    function populateTokenData(
        ExchangeData memory exchangeData,
        SpotMarketAmm amm,
        address user
    ) private view {
        ERC20 assetToken = ERC20(amm.assetToken());
        exchangeData.assetToken = Token({
            tokenAddress: address(assetToken),
            totalSupply: assetToken.totalSupply(),
            userBalance: assetToken.balanceOf(user),
            decimals: assetToken.decimals(),
            symbol: assetToken.symbol()
        });

        ERC20 stableToken = ERC20(amm.stableToken());
        exchangeData.stableToken = Token({
            tokenAddress: address(stableToken),
            totalSupply: stableToken.totalSupply(),
            userBalance: stableToken.balanceOf(user),
            decimals: stableToken.decimals(),
            symbol: stableToken.symbol()
        });

        exchangeData.tokens = amm.ammAdapter().supportedTokens();
    }

    function populateLiquidityTokenData(
        Liquidity memory liquidityData,
        SpotMarketAmm amm,
        address user
    ) private view {
        StakingIncentives liquidityIncentives = StakingIncentives(amm.liquidityIncentives());
        LiquidityToken liquidityToken = LiquidityToken(address(amm.liquidityToken()));
        liquidityData.liquidityToken = Token({
            tokenAddress: address(liquidityToken),
            totalSupply: liquidityToken.totalSupply(),
            userBalance: liquidityIncentives.getBalance(user),
            decimals: liquidityToken.decimals(),
            symbol: liquidityToken.symbol()
        });
    }

    function populateLiquidityData(
        Liquidity memory liquidityData,
        SpotMarketAmm amm,
        address user
    ) private view {
        uint256 totalSupply = liquidityData.liquidityToken.totalSupply;
        if (totalSupply > 0) {
            StakingIncentives liquidityIncentives = StakingIncentives(amm.liquidityIncentives());
            uint256 userBalance = liquidityData.liquidityToken.userBalance;

            (int256 userAssetAmount, int256 userStableAmount) =
                amm.getLiquidityValue(FsMath.safeCastToSigned(userBalance));
            liquidityData.userAssetAmount = FsMath.safeCastToUnsigned(userAssetAmount);
            liquidityData.userStableAmount = FsMath.safeCastToUnsigned(userStableAmount);

            (int256 exchangeAssetAmount, int256 exchangeStableAmount) =
                amm.getLiquidityValue(FsMath.safeCastToSigned(totalSupply));
            liquidityData.exchangeAssetAmount = FsMath.safeCastToUnsigned(exchangeAssetAmount);
            liquidityData.exchangeStableAmount = FsMath.safeCastToUnsigned(exchangeStableAmount);

            (uint256 amount, uint256 timestamp) = liquidityIncentives.withdrawRequests(user);
            liquidityData.withdrawRequest.amount = amount;
            liquidityData.withdrawRequest.timestamp = timestamp;

            int256 redeemableAmount = amm.getRedeemableLiquidityTokenAmount();
            liquidityData.redeemableAmount = FsMath.safeCastToUnsigned(redeemableAmount);
        }
    }

    function populateLiquidityIncentivesData(
        ExchangeData memory exchangeData,
        SpotMarketAmm amm,
        address user
    ) private view {
        // slither-disable-next-line uninitialized-local
        IncentivesData memory incentivesData;
        incentivesData.vesting = computeRewardsVesting(
            LockBalanceIncentives(amm.liquidityIncentives()),
            user
        );
        StakingIncentives liquidityIncentives = StakingIncentives(amm.liquidityIncentives());
        incentivesData.distribution = liquidityIncentives.rewardRate();
        incentivesData.claimable = liquidityIncentives.getClaimableTokens(user);
        exchangeData.liquidityProviderIncentives = incentivesData;
    }

    function populateExchangeConfigAndState(
        ExchangeData memory exchangeData,
        ExchangeLedger exchangeLedger,
        SpotMarketAmm amm
    ) private view {
        (
            int256 tradeFee,
            int256 timeFee,
            uint256 maxLeverage,
            uint256 minCollateral,
            ,
            int256 dfrRate,
            ,
            ,
            ,
            ,

        ) = exchangeLedger.exchangeConfig();
        (int256 removeLiquidityFee, ) = amm.ammConfig();
        exchangeData.exchangeConfig.tradeFee = FsMath.safeCastToUnsigned(tradeFee);
        exchangeData.exchangeConfig.timeFee = FsMath.safeCastToUnsigned(timeFee);
        exchangeData.exchangeConfig.maxLeverage = maxLeverage;
        exchangeData.exchangeConfig.minCollateral = minCollateral;
        exchangeData.exchangeConfig.dfrRate = FsMath.safeCastToUnsigned(dfrRate);
        exchangeData.exchangeConfig.removeLiquidityFee = FsMath.safeCastToUnsigned(
            removeLiquidityFee
        );
        exchangeData.exchangeConfig.exchangeState = exchangeLedger.exchangeState();
    }

    function populateOpenInterestData(
        ExchangeData memory exchangeData,
        ExchangeLedger exchangeLedger
    ) private view {
        (int256 openAsset, , , ) = exchangeLedger.packedFundingData();
        int256 assetPrice = FsMath.safeCastToSigned(exchangeData.indexPrice);
        (, int256 ammAsset) = exchangeLedger.getAmmPosition(assetPrice, block.timestamp);

        // Open asset is the same on both sides (longs vs shorts) because the AMM takes the opposite position to all
        // traders. We need to remove the AMM position from the total open interest.
        int256 longPositionAsset = openAsset;
        int256 shortPositionAsset = openAsset;
        if (ammAsset > 0) {
            // AMM position is long (positive ammAsset) so remove AMM position from the long side.
            longPositionAsset -= ammAsset;
        } else {
            // AMM position is short (negative ammAsset) so remove AMM position from the short side.
            shortPositionAsset += ammAsset;
        }

        // Long position asset should be positive and short position asset should be negative.
        exchangeData.longPositionAsset = longPositionAsset;
        exchangeData.shortPositionAsset = -shortPositionAsset;
    }

    function populateUserPositionData(
        ExchangeData memory exchangeData,
        ExchangeLedger exchangeLedger,
        address user,
        uint256 time
    ) private view {
        int256 assetPrice = FsMath.safeCastToSigned(exchangeData.indexPrice);
        (int256 asset, int256 stable, uint32 trancheId) =
            exchangeLedger.getPosition(user, assetPrice, time);
        exchangeData.position.asset = asset;
        exchangeData.position.stable = stable;
        exchangeData.position.trancheId = trancheId;
    }

    function populateTradeIncentivesData(
        ExchangeData memory exchangeData,
        IncentivesHook incentivesHook,
        address user
    ) private view {
        uint8 openInterestIncentivesCount = incentivesHook.openInterestIncentivesCount();
        exchangeData.openInterestIncentives = new IncentivesData[](openInterestIncentivesCount);
        for (uint8 i = 0; i < openInterestIncentivesCount; i++) {
            LockBalanceIncentives incentives =
                LockBalanceIncentives(incentivesHook.openInterestIncentivesContracts(i));
            IncentivesData memory incentivesData = exchangeData.openInterestIncentives[i];
            incentivesData.vesting = computeRewardsVesting(incentives, user);
            incentivesData.distribution = incentives.rewardRate();
            incentivesData.claimable = incentives.getClaimableTokens(user);
        }

        uint8 tradingFeeIncentivesCount = incentivesHook.tradingFeeIncentivesCount();
        exchangeData.tradingFeeIncentives = new IncentivesData[](tradingFeeIncentivesCount);
        for (uint8 i = 0; i < tradingFeeIncentivesCount; i++) {
            ITradingFeeIncentives incentives =
                ITradingFeeIncentives(incentivesHook.tradingFeeIncentivesContracts(i));
            IncentivesData memory incentivesData = exchangeData.tradingFeeIncentives[i];
            incentivesData.vesting = computeTradingFeeIncentivesVesting(incentives, user);

            // Avoid division by zero.
            uint256 periodLength = incentives.periodLength();
            incentivesData.distribution = periodLength > 0
                ? incentives.currentPeriodRewards() / incentives.periodLength()
                : 0;
            incentivesData.claimable = incentives.getClaimableTokens(user);
        }
    }

    function populateExternalIncentivesData(
        ExchangeData memory exchangeData,
        address externalIncentivesAddress,
        address user
    ) private view {
        if (externalIncentivesAddress != address(0)) {
            ExternalLiquidityIncentives incentives =
                ExternalLiquidityIncentives(externalIncentivesAddress);

            // slither-disable-next-line uninitialized-local
            IncentivesData memory incentivesData;
            incentivesData.vesting = computeExternalLiquidityIncentivesVesting(incentives, user);
            // `ExternalLiquidityIncentives` has no reward rate, the rewards are computed off-chain.
            incentivesData.distribution = 0;
            incentivesData.claimable = incentives.claimableTokens(user);

            exchangeData.externalLiquidityIncentives = incentivesData;
        }
    }

    function computeRewardsVesting(LockBalanceIncentives incentives, address user)
        private
        view
        returns (RewardsVesting[] memory)
    {
        uint256 rewardsVestingCount = incentives.requestIdByAddress(user);
        uint256 length =
            rewardsVestingCount > MAX_ITERATIONS ? MAX_ITERATIONS : rewardsVestingCount;
        RewardsVesting[] memory rewardsVesting = new RewardsVesting[](length);
        for (uint256 i = 0; i < length; i++) {
            // This function is only called by the frontend in a `callStatic` invocation that does
            // not spend gas.  And we also hope that, `MAX_ITERATIONS` limit will prevent us from
            // failing here.  TODO We may want to improve the robustness of this approach at some
            // point.
            // slither-disable-next-line calls-loop
            (uint256 amount, uint256 availableTimestamp) = incentives.getRewards(user, i);
            rewardsVesting[i] = RewardsVesting({
                rewardAmount: amount,
                availableTimestamp: availableTimestamp
            });
        }
        return rewardsVesting;
    }

    function computeExternalLiquidityIncentivesVesting(
        ExternalLiquidityIncentives incentives,
        address user
    ) private view returns (RewardsVesting[] memory) {
        TokenLocker tokenLocker = TokenLocker(incentives.tokenLocker());
        return computeTokenLockerVesting(tokenLocker, user);
    }

    function computeTradingFeeIncentivesVesting(ITradingFeeIncentives incentives, address user)
        private
        view
        returns (RewardsVesting[] memory)
    {
        TokenLocker tokenLocker = TokenLocker(incentives.tokenLocker());
        return computeTokenLockerVesting(tokenLocker, user);
    }

    function computeTokenLockerVesting(TokenLocker tokenLocker, address user)
        private
        view
        returns (RewardsVesting[] memory)
    {
        uint256 rewardsVestingCount = tokenLocker.requestIdByAddress(user);
        uint256 length =
            rewardsVestingCount > MAX_ITERATIONS ? MAX_ITERATIONS : rewardsVestingCount;
        RewardsVesting[] memory rewardsVesting = new RewardsVesting[](length);
        for (uint256 i = 0; i < length; i++) {
            // This function is only called by the frontend in a `callStatic` invocation that does
            // not spend gas.  And we also hope that, `MAX_ITERATIONS` limit will prevent us from
            // failing here.  TODO We may want to improve the robustness of this approach at some
            // point.
            // slither-disable-next-line calls-loop
            (uint256 amount, uint256 availableTimestamp) = tokenLocker.getRewards(user, i);
            rewardsVesting[i] = RewardsVesting({
                rewardAmount: amount,
                availableTimestamp: availableTimestamp
            });
        }
        return rewardsVesting;
    }
}