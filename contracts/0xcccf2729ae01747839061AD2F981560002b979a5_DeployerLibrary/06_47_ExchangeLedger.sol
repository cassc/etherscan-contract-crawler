//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../lib/FsMath.sol";
import "../lib/Utils.sol";
import "../upgrade/FsBase.sol";
import "./interfaces/IAmm.sol";
import "./interfaces/IExchangeLedger.sol";
import "./interfaces/IExchangeHook.sol";

library Packing {
    struct Position {
        int128 asset;
        int128 stableExcludingFunding;
    }

    struct EntranchedPosition {
        int112 shares;
        int112 stableExcludingFundingTranche;
        uint32 trancheIdx;
    }

    struct TranchePosition {
        Position position;
        int256 totalShares;
    }

    struct Funding {
        /// @notice Because of invariant (2), longAsset == shortAsset, so we only need to keep track of one.
        int128 openAsset;
        /// @notice Accumulates stable paid by longs for time fees and DFR.
        int128 longAccumulatedFunding;
        /// @notice Accumulates stable paid by shorts for time fees and DFR.
        int128 shortAccumulatedFunding;
        /// @notice Last time that funding was updated.
        uint128 lastUpdatedTimestamp;
    }
}

/// @title The implementation of Futureswap's V4.1 exchange.
/// The ExchangeLedger keeps track of the position of all traders (including the AMM) that interact with
/// the system. A position of a trader is just its asset and stable balance.
/// A trade is an exchange of asset and stable between two traders, and is reflected
/// by the elementary function `tradeInternal`. Stable corresponds to an actual ERC20 that is
/// used for collateral in the system (usually a stable token, hence its name, but note that this is not
/// actually a restriction, and in fact we could have any ERC20 as stable). On the other hand, asset can
/// be synthetic, depending on the AMM (in our SpotMarketAmm, asset is directly tied to ERC20).
/// The invariants are thus:
///
/// (1) sum_traders stable(trader) = sum stable ERC20 send in - ERC20 send out = stableToken.balance(vault)
/// (2) sum_traders asset(trader) = 0
///
/// The value of a position is `stable(trader) + priceAssetInStable * asset(trader)`.
/// Using invariant (2), it's easy to see that the total value of all positions equals the stable token
/// balance in the vault. Furthermore, if no position has negative value (bankrupt) this implies that we
/// can close out all positions and return every trader the proper value of its position. For this reason,
/// we have a `liquidate` function that anybody can call to eliminate positions near bankruptcy and keep
/// the system safe.
///
/// Under normal operation, the AMM acts as another trader that is the counter-party to all trades
/// happening in the system. However, the AMM can reject a trade (ie. revert), for example,
/// in our SpotMarketAmm if there is not enough liquidity in the AMM to hedge the trade on a spot market.
/// If this is the case, then normally the exchange would reject the trade. However, there are situations
/// where it won't reject the trade. Liquidations and closes should not be rejected.
/// Liquidations should not be rejected because failing to eliminate bankrupt positions poses risk to the
/// integrity of the system. Closes should not be rejected because we want traders to always be able to exit
/// the system. In these cases, the system resorts to executing the trade against other traders as counter-party,
/// this is called `ADL` (Auto DeLeveraging).
///
/// ADL:
/// ADL is the most complicated part of the system. The blockchain constrains do not allow iterating over
/// all traders, so we need to be able to trade against traders in aggregate. ADL is essentially forcing
/// a trade on traders against their explicit wish to do so. Therefore we have another constraint from a
/// product design perspective that ADL'ing should happen against the riskiest traders first.
///
/// We met these constraints by aggregating traders based on their leverage (risk) and long/short into
/// tranches. For instance, if we ADL a long, we iterate over the short tranches from riskiest to
/// safest and iterate until we're done. If the long is still not fully closed, we ADL the remaining
/// against the AMM position (the AMM as a trader doesn't participate in any tranche).
///
/// Because we bundle trades into tranches, the actual data structure for a trader is `EntranchedPosition`
/// which consist of (trancheShares, stable, trancheIdx). And we have the following triangular matrix
/// transformation, to translate between them.
///
/// asset(trader)  = | asset(tranche)/totalTrancheShares   0 | x | trancheShares(trader) |
/// stable(trader)   | stable(tranche)/totalTrancheShares  1 |   | stable(trader)        |
///
/// We structured the code to first extract the trader position from the tranche, execute the trade,
/// and then insert the trade back in a tranche (could be a different one than the original).
/// ADL'ing simply executes a trade against the position of the tranche. One extra complication is that
/// over time, the above matrix can become ill-conditioned (ie. become singular and non-invertible).
/// This happens when `asset(tranche)/totalTrancheShares` becomes small. When we detect this case,
/// we ditch the tranche and start a new one. See `TRANCHE_INFLATION_MAX`.
///
/// Funding:
/// The system charges time fees and dynamic funding rate (DFR).
/// These fees are continuously charged over time and paid in stable. Both fees are designed such that
/// they are only dependent on the asset value of the position.
/// Because we cannot loop over all positions to update the positions with the correct funding at each time
/// we use a funding pot that each position has a share in (actually two pots one for long and one for short positions,
/// in the code called `longAccumulatedFunding` and `shortAccumulatedFunding`).
/// This way updating funding is a O(1) step of just updating the pot. Each positions share in the pot is
/// determined by the size of the position giving precisely the correct proportional funding rate.
/// The consequence is that a positions actual amount of stable satisfies
///        `stable = stable_without_funding + share_of_funding_pot`
/// We store stable_without_funding as it doesn't change on funding updates. This means that in order to correctly state
/// a position we need to add the share_of_funding_pot, this matters at all places where we calculate the value of
/// the position (for leverage/liquidation) or to calculate the execution price.
/// This accounting is similar to how we do tranches, by extracting the position out of the funding pool
/// before the trade and inserting it back in after the trade.
contract ExchangeLedger is IExchangeLedger, FsBase {
    /// @notice The maximum amount of long tranches and short tranches.
    /// If this constant is set to x there can be x long tranches and x short tranches.
    uint8 private constant MAX_TRANCHES = 10;

    /// @notice When tranches are getting ADL'ed the share ratio per asset share of their respective
    /// main position changes. Once this moves past a certain point we run the risk of rounding
    /// errors becoming signicant. This constant denominates when to switch over to a new tranche.
    int256 private constant TRANCHE_INFLATION_MAX = 1000;

    /// @notice Struct that contains all the funding related information. Useful to bundle all the funding
    /// data at the beginning of a trade operation, manipulate it in memory, and save it back into storage
    /// at the end.
    struct Funding {
        int256 longAccumulatedFunding;
        int256 longAsset;
        int256 shortAccumulatedFunding;
        // While at the beginning/end of the `doChangePosition`
        // longAsset == shortAsset (because of invariant 2), this is not true after extracting
        // a single position (see `tradeInternal`).
        int256 shortAsset;
        uint256 lastUpdatedTimestamp;
    }

    /// @notice Elemental building block used to represent a position.
    struct Position {
        int256 asset;
        int256 stableExcludingFunding;
    }

    /// @notice Used to represent the position of a trader in storage.
    struct EntranchedPosition {
        // Share of the tranche asset and stable that this position owns.
        // The total number of shares is stored in the tranche as `totalShares`.
        int256 trancheShares;
        // Stable that this trader owns in addition to their stable share from the tranche.
        int256 stableExcludingFundingTranche;
        // Tranche that contains the trader's position.
        uint32 trancheIdx;
    }

    /// @notice Used to represent the position of a tranche in storage.
    struct TranchePosition {
        // The actual position of the tranche. Each trader within the tranche owns a fraction of this
        // position, given by `EntranchedPosition.trancheShares / TranchePosition.totalShares`.
        Position position;
        // Total number of shares in this tranche. It holds the invariant that this number is equal
        // to the sum of all EntranchedPosition.trancheShares where EntranchedPosition.trancheIdx is
        // equal to the index of this tranche.
        int256 totalShares;
    }

    /// @notice The AMM is considered just another trader in the system, with the exception that it doesn't
    /// belong to any tranche, so it's position can be represented with `Position` instead of `EntranchedPosition`
    Packing.Position public ammPosition;

    /// @notice Each trader can have at most one position in the exchange at any given time.
    mapping(address => Packing.EntranchedPosition) public traderPositions;

    /// @notice Map from trancheId to tranche position (see definition of trancheId below).
    mapping(uint32 => Packing.TranchePosition) public tranchePositions;

    /// @notice The system can have MAX_TRANCHES long tranches and MAX_TRANCHES short tranches, and they
    /// are assigned an id, which is represented in this map. The id of a tranche changes when the tranche
    /// reaches the TRANCHE_INFLATION_MAX, and a new tranche is created. `nextTrancheIdx` keeps track
    /// of the next id that can be used.
    mapping(uint8 => uint32) public trancheIds;
    uint32 private nextTrancheIdx;

    Packing.Funding public packedFundingData;

    ExchangeConfig public exchangeConfig;
    // Storage gaps for extending exchange config in the future.
    // slither-disable-next-line unused-state
    uint256[52] ____configStorageGap;

    /// @inheritdoc IExchangeLedger
    ExchangeState public override exchangeState;
    /// @inheritdoc IExchangeLedger
    int256 public override pausePrice;

    address public tradeRouter;
    IAmm public override amm;
    IExchangeHook public hook;
    address public treasury;

    /// @dev Reserves storage for future upgrades. Each contract will use exactly storage slot 1000 until 2000.
    /// When adding new fields to this contract, one must decrement this counter proportional to the
    /// number of uint256 slots used.
    //slither-disable-next-line unused-state
    uint256[924] private _____contractGap;

    /// @notice Only for testing our contract gap mechanism, never use in prod.
    //slither-disable-next-line constable-states,unused-state
    uint256 private ___storageMarker;

    function initialize(address _treasury) external initializer {
        //slither-disable-next-line missing-zero-check
        treasury = nonNull(_treasury);
        initializeFsOwnable();
    }

    /// @inheritdoc IExchangeLedger
    function changePosition(
        address trader,
        int256 deltaAsset,
        int256 deltaStable,
        int256 stableBound,
        int256 oraclePrice,
        uint256 time
    ) external override returns (Payout[] memory, bytes memory) {
        require(msg.sender == tradeRouter, "Only TradeRouter");

        //slither-disable-next-line uninitialized-local
        ChangePositionData memory cpd;
        cpd.trader = trader;
        cpd.deltaAsset = deltaAsset;
        cpd.deltaStable = deltaStable;
        cpd.stableBound = stableBound;
        cpd.time = time;
        cpd.oraclePrice = oraclePrice;

        return doChangePosition(cpd);
    }

    /// @inheritdoc IExchangeLedger
    function liquidate(
        address trader,
        address liquidator,
        int256 oraclePrice,
        uint256 time
    ) external override returns (Payout[] memory, bytes memory) {
        require(msg.sender == tradeRouter, "Only TradeRouter");

        //slither-disable-next-line uninitialized-local
        ChangePositionData memory cpd;
        cpd.trader = trader;
        cpd.liquidator = liquidator;
        cpd.time = time;
        cpd.oraclePrice = oraclePrice;

        return doChangePosition(cpd);
    }

    /// @inheritdoc IExchangeLedger
    function getPosition(
        address trader,
        int256 price,
        uint256 time
    )
        external
        view
        override
        returns (
            int256,
            int256,
            uint32
        )
    {
        // Load Amm position and funding data into memory to avoid repeatedly reading from storage.
        Funding memory fundingData = loadFunding();
        Position memory ammPositionMem = loadPosition(ammPosition);
        updateFunding(ammPositionMem, fundingData, time, price);
        (Position memory traderPosition, , uint32 trancheIdx) = extractPosition(trader);
        int256 stable = stableIncludingFunding(traderPosition, fundingData);
        return (traderPosition.asset, stable, trancheIdx);
    }

    /// @inheritdoc IExchangeLedger
    function getAmmPosition(int256 price, uint256 time)
        external
        view
        override
        returns (int256 stableAmount, int256 assetAmount)
    {
        // Load Amm position and funding data into memory to avoid repeatedly reading from storage.
        Funding memory fundingData = loadFunding();
        Position memory ammPositionMem = loadPosition(ammPosition);
        updateFunding(ammPositionMem, fundingData, time, price);
        int256 stable = stableIncludingFunding(ammPositionMem, fundingData);
        // TODO(gerben): return (asset, stable) instead of (stable, asset) for consistency with all our other APIs.
        return (stable, ammPositionMem.asset);
    }

    // doChangePosition loads all necessary data in memory and after calling
    // doChangePositionMemory stores the updated state back.
    function doChangePosition(ChangePositionData memory cpd)
        private
        returns (Payout[] memory, bytes memory)
    {
        //slither-disable-next-line uninitialized-local
        // Passing zero for asset and stable is treated as closing a trade.
        // The trader can not simply pass in the reverse of their position since the position might slightly change
        // because of funding and mining timestamp.
        cpd.isClosing = cpd.deltaAsset == 0 && cpd.deltaStable == 0;

        // Makes sure the exchange is allowed to changePositions right now
        {
            ExchangeState state = exchangeState;
            require(state != ExchangeState.STOPPED, "Exchange stopped, can't change position");

            if (state == ExchangeState.PAUSED) {
                require(cpd.isClosing, "Exchange paused, only closing positions");
            }
        }

        // Load Amm position and funding data into memory to avoid repeatedly reading from storage.
        Funding memory fundingData = loadFunding();
        Position memory ammPositionMem = loadPosition(ammPosition);

        // Updates the funding for all traders. This has to be done before loading a specific trader
        // so that these changes are reflected in the traders position.
        (cpd.timeFeeCharged, cpd.dfrCharged) = updateFunding(
            ammPositionMem,
            fundingData,
            cpd.time,
            cpd.oraclePrice
        );

        // Load the trader's position from storage and remove them from the tranche.
        (
            Position memory traderPositionMem,
            TranchePosition memory tranchePosition,
            uint32 trancheIdx
        ) = extractPosition(cpd.trader);
        // This removes the trader's position from the tranche. Trader will be added to a tranche later after the swap.
        storeTranchePosition(tranchePositions[trancheIdx], tranchePosition);
        Payout[] memory payouts =
            doChangePositionMemory(cpd, traderPositionMem, ammPositionMem, fundingData);

        // Save the updated funding data to storage
        storeFunding(fundingData);

        // Save the Amm position to storage
        storePosition(ammPosition, ammPositionMem);

        // Save the trader position to storage.
        insertPosition(fundingData, cpd.trader, traderPositionMem, cpd.oraclePrice);

        return (payouts, abi.encode(cpd));
    }

    // The logic of the exchange. Works mostly on loaded memory. Except for
    // tranches which are updated in storage on ADL.
    function doChangePositionMemory(
        ChangePositionData memory cpd,
        Position memory traderPositionMem,
        Position memory ammPositionMem,
        Funding memory fundingData
    ) private returns (Payout[] memory) {
        // If the change position is a liquidation make sure the trade can actually be liquidated
        if (cpd.liquidator != address(0)) {
            require(
                canBeLiquidated(
                    traderPositionMem.asset,
                    stableIncludingFunding(traderPositionMem, fundingData),
                    cpd.oraclePrice
                ),
                "Position not liquidatable"
            );
        }

        // Capture the start asset and stable of the trader for the PositionChangedEvent
        cpd.startAsset = traderPositionMem.asset;
        cpd.startStable = stableIncludingFunding(traderPositionMem, fundingData);

        // If the user added stable, add it to his position. We are not deducing stable here since this is handled
        // in payments after the swap is performed.
        if (cpd.deltaStable > 0) {
            traderPositionMem.stableExcludingFunding += cpd.deltaStable;
        }

        // If the trade is closing we need to revert the asset position.
        if (cpd.isClosing) {
            cpd.deltaAsset = -traderPositionMem.asset;
        }

        bool isPartialOrFullClose =
            computeIsPartialOrFullClose(traderPositionMem.asset, cpd.deltaAsset);
        int256 stableSwappedAgainstPool = 0;
        {
            int256 prevAsset = traderPositionMem.asset;
            int256 prevStable = stableIncludingFunding(traderPositionMem, fundingData);
            // If we do not have a change in deltaAsset we do not need to perform a swap.
            if (cpd.deltaAsset != 0) {
                // The amm trade is done in a different execution context. This allows the amm to revert and
                // guarantee no state change in the amm. For instance for a spot market amm, if the amm
                // determines that after the swap on the spot market it's left with not enough liquidity
                // reserved it can safely revert.
                // If the swap succeeded, `stableSwappedAgainstPool` contains the amount of stable
                // that the trader received / paid (if negative).

                // We trust amm.
                //slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events,unused-return
                try amm.trade(cpd.deltaAsset, cpd.oraclePrice, isPartialOrFullClose) returns (
                    //slither-disable-next-line uninitialized-local
                    int256 stableSwapped
                ) {
                    // Slither 0.8.2 does not understand the try/retrurns constract, claiming
                    // `stableSwapped` could be used before it is initialized.
                    // slither-disable-next-line variable-scope
                    stableSwappedAgainstPool = stableSwapped;
                    // If the swap succeeded make sure the trader's bounds are met otherwise revert
                    requireStableBound(cpd.stableBound, stableSwappedAgainstPool);
                    // Update the trader position to their new position
                    tradeInternal(
                        traderPositionMem,
                        ammPositionMem,
                        fundingData,
                        cpd.deltaAsset,
                        stableSwappedAgainstPool
                    );
                } catch {
                    // If we could not do a trade with the AMM, ADL can kick in to allow trader to close their positions
                    // However, we don't allow ADL to apply on non-closing trades.
                    require(isPartialOrFullClose, "IVS");
                    stableSwappedAgainstPool = adlTrade(
                        cpd.deltaAsset,
                        cpd.stableBound,
                        cpd.liquidator != address(0),
                        cpd.oraclePrice,
                        traderPositionMem,
                        ammPositionMem,
                        fundingData
                    );
                    // We do not need to call `requireStableBound()` here. ADL handles bounds internally since they are
                    // slightly different to regular bounds.
                }
            }
            if (traderPositionMem.asset != prevAsset) {
                int256 newStable = stableIncludingFunding(traderPositionMem, fundingData);
                cpd.executionPrice =
                    (-(newStable - prevStable) * FsMath.FIXED_POINT_BASED) /
                    (traderPositionMem.asset - prevAsset);
            }
        }

        // Compute payments to all actors
        if (cpd.liquidator != address(0)) {
            computeLiquidationPayments(traderPositionMem, ammPositionMem, cpd);
        } else {
            computeTradePayments(traderPositionMem, ammPositionMem, cpd, stableSwappedAgainstPool);
        }

        if (cpd.liquidator == address(0)) {
            // Liquidation check needs to be performed here since the trade might be in a liquidatable state after the
            // swap and paying its fees
            require(
                (cpd.isClosing && traderPositionMem.stableExcludingFunding == 0) ||
                    !canBeLiquidated(
                        traderPositionMem.asset,
                        stableIncludingFunding(traderPositionMem, fundingData),
                        cpd.oraclePrice
                    ),
                "Trade liquidatable after change position"
            );
        }

        // If the user does not have a position but still has stable we pay him out.
        if (traderPositionMem.asset == 0 && traderPositionMem.stableExcludingFunding > 0) {
            // Because asset is 0 the position has no contribution from funding
            cpd.traderPayment += traderPositionMem.stableExcludingFunding;
            traderPositionMem.stableExcludingFunding = 0;
        }

        cpd.totalAsset = traderPositionMem.asset;
        cpd.totalStable = stableIncludingFunding(traderPositionMem, fundingData);

        if (address(hook) != address(0)) {
            // Call the hook as a fire-and-forget so if anything fails, the transaction will not revert.
            // Slither is confused about `reason`, claiming it is not initialized.
            // slither-disable-next-line uninitialized-local
            try hook.onChangePosition(cpd) {} catch Error(string memory reason) {
                // Slither 0.8.2 does not understand the try/retrurns constract, claiming `reason`
                // could be used before it is initialized.
                // slither-disable-next-line variable-scope
                emit OnChangePositionHookFailed(reason, cpd);
            } catch {
                emit OnChangePositionHookFailed("No revert reason", cpd);
            }
        }
        emit PositionChanged(cpd);

        // Record payouts that need to be made to external parties. TradeRouter will make the payments accordingly.
        return recordPayouts(treasury, cpd);
    }

    /// @dev Update internal accounting for a trade between two given parties. Accounting invariants should be
    /// maintained with all credits being matched by debits.
    function tradeInternal(
        Position memory traderPosition,
        Position memory counterPartyPosition,
        Funding memory fundingData,
        int256 deltaAsset,
        int256 deltaStable
    ) private pure {
        extractFromFunding(traderPosition, fundingData);
        extractFromFunding(counterPartyPosition, fundingData);
        traderPosition.asset += deltaAsset;
        counterPartyPosition.asset -= deltaAsset;
        traderPosition.stableExcludingFunding += deltaStable;
        counterPartyPosition.stableExcludingFunding -= deltaStable;
        insertInFunding(counterPartyPosition, fundingData);
        insertInFunding(traderPosition, fundingData);
        FsUtils.Assert(fundingData.longAsset == fundingData.shortAsset);
    }

    function computeIsPartialOrFullClose(int256 startingAsset, int256 deltaAsset)
        private
        pure
        returns (bool)
    {
        uint256 newPositionSize = FsMath.abs(startingAsset + deltaAsset);
        uint256 oldPositionSize = FsMath.abs(startingAsset);
        uint256 positionChange = FsMath.abs(deltaAsset);
        return newPositionSize < oldPositionSize && positionChange <= oldPositionSize;
    }

    function requireStableBound(int256 stableBound, int256 stableSwapped) private pure {
        // A stableBound of zero means no bound
        if (stableBound == 0) {
            return;
        }

        // 1. A long trade opening:
        //    stableSwapped will be a negative number (payed by the user),
        //    users are expected to set a lower negative number
        // 2. A short trade opening:
        //    stableSwapped will be a positive number (stable received by the user)
        //    The user is expected to set a lower positive number
        // 3. A long trade closing:
        //    stableSwapped will be a positive number (stable received by the user)
        //    The user is expected to set a lower positve number
        // 4. A short trade closing
        //    stableSwapped will be a negative number (stable payed by the user)
        //    The user is expected to set a lower negative number
        require(stableBound <= stableSwapped, "Trade stable bounds violated");
    }

    function computeLiquidationPayments(
        Position memory traderPositionMem,
        Position memory ammPositionMem,
        ChangePositionData memory cpd
    ) private view {
        // After liquidation there should be no net position
        FsUtils.Assert(traderPositionMem.asset == 0);
        // Because asset == 0 we don't need to include funding

        //slither-disable-next-line uninitialized-local
        int256 remainingCollateral = traderPositionMem.stableExcludingFunding;
        traderPositionMem.stableExcludingFunding = 0;

        if (remainingCollateral <= 0) {
            // The position is bankrupt and so pool takes the loss.
            ammPositionMem.stableExcludingFunding += remainingCollateral;
            return;
        }

        int256 liquidatorFee =
            (remainingCollateral * exchangeConfig.liquidatorFrac) / FsMath.FIXED_POINT_BASED;
        liquidatorFee = FsMath.min(liquidatorFee, exchangeConfig.maxLiquidatorFee);
        cpd.liquidatorPayment = liquidatorFee;

        int256 poolLiquidationFee =
            (remainingCollateral * exchangeConfig.poolLiquidationFrac) / FsMath.FIXED_POINT_BASED;
        poolLiquidationFee = FsMath.min(poolLiquidationFee, exchangeConfig.maxPoolLiquidationFee);
        ammPositionMem.stableExcludingFunding += poolLiquidationFee;

        int256 sumFees = liquidatorFee + poolLiquidationFee;
        cpd.tradeFee = sumFees;
        remainingCollateral -= sumFees;
        cpd.traderPayment = remainingCollateral;

        // treasury payment comes from the poolLiquidationFee and not the full remainingCollateral
        cpd.treasuryPayment =
            (poolLiquidationFee * exchangeConfig.treasuryFraction) /
            FsMath.FIXED_POINT_BASED;
        ammPositionMem.stableExcludingFunding -= cpd.treasuryPayment;
    }

    function computeTradePayments(
        Position memory traderPositionMem,
        Position memory ammPositionMem,
        ChangePositionData memory cpd,
        int256 stableSwapped
    ) private view {
        // If closing the net asset should be zero.
        FsUtils.Assert(!cpd.isClosing || traderPositionMem.asset == 0);

        if (cpd.isClosing && traderPositionMem.stableExcludingFunding < 0) {
            // Trade is bankrupt, pool acquires the loss
            // Because asset is zero we don't need funding
            ammPositionMem.stableExcludingFunding += traderPositionMem.stableExcludingFunding;
            traderPositionMem.stableExcludingFunding = 0;
            return;
        }

        // Trade fee is a percentage on the size of the trade (ie stableSwapped)
        int256 tradeFee =
            (FsMath.sabs(stableSwapped) * exchangeConfig.tradeFeeFraction) /
                FsMath.FIXED_POINT_BASED;
        cpd.tradeFee = tradeFee;
        traderPositionMem.stableExcludingFunding -= tradeFee;
        ammPositionMem.stableExcludingFunding += tradeFee;

        // Above we checked that if closing the asset is zero, so we do not
        // need the funding correction.  And then `stableExcludingFunding`
        // contains an accurate stable value.
        int256 traderPayment =
            cpd.isClosing
                ? traderPositionMem.stableExcludingFunding > 0
                    ? traderPositionMem.stableExcludingFunding
                    : int256(0)
                : (cpd.deltaStable < 0 ? -cpd.deltaStable : int256(0));
        traderPositionMem.stableExcludingFunding -= traderPayment; //  This is compensated by ERC20 transfer to trader
        cpd.traderPayment = traderPayment;
        cpd.treasuryPayment =
            (tradeFee * exchangeConfig.treasuryFraction) /
            FsMath.FIXED_POINT_BASED;
        ammPositionMem.stableExcludingFunding -= cpd.treasuryPayment; // Compensated by treasury payment
    }

    function recordPayouts(address _treasury, ChangePositionData memory cpd)
        private
        pure
        returns (Payout[] memory payouts)
    {
        // Create a fixed array of payouts as there's no way to add to a dynamic array in memory.
        // slither-disable-next-line uninitialized-local
        Payout[3] memory tmpPayouts;
        uint256 payoutCount = 0;
        if (cpd.traderPayment > 0) {
            // slither-disable-next-line safe-cast
            tmpPayouts[payoutCount++] = Payout(cpd.trader, uint256(cpd.traderPayment));
        }

        if (cpd.liquidator != address(0) && cpd.liquidatorPayment > 0) {
            // slither-disable-next-line safe-cast
            tmpPayouts[payoutCount++] = Payout(cpd.liquidator, uint256(cpd.liquidatorPayment));
        }

        if (cpd.treasuryPayment > 0) {
            // For internal payments we use ERC20 exclusively, so that our
            // contracts do not need to be able to receive ETH.
            // slither-disable-next-line safe-cast
            tmpPayouts[payoutCount++] = Payout(_treasury, uint256(cpd.treasuryPayment));
        }
        payouts = new Payout[](payoutCount);
        // Convert fixed array to dynamic so we don't have gaps.
        for (uint256 i = 0; i < payoutCount; i++) payouts[i] = tmpPayouts[i];
        return payouts;
    }

    function calculateTranche(
        Position memory traderPositionMem,
        int256 price,
        Funding memory fundingData
    ) private view returns (uint8) {
        uint256 leverage =
            FsMath.calculateLeverage(
                traderPositionMem.asset,
                stableIncludingFunding(traderPositionMem, fundingData),
                price
            );
        uint256 trancheLevel = (MAX_TRANCHES * leverage) / exchangeConfig.maxLeverage;
        bool isLong = traderPositionMem.asset > 0;
        uint256 trancheIdAsUint256 = (trancheLevel << 1) + (isLong ? 0 : 1);

        require(trancheIdAsUint256 < 2 * MAX_TRANCHES, "Over max tranches limit");
        // The above check validates that `trancheIdAsUint256` fits into `uint8` as long as
        // `MAX_TRANCHES` is below 128.  It is currently set to 10.
        // slither-disable-next-line safe-cast
        return uint8(trancheIdAsUint256);
    }

    function extractPosition(address trader)
        private
        view
        returns (
            Position memory,
            TranchePosition memory,
            uint32
        )
    {
        EntranchedPosition memory traderPosition = loadEntranchedPosition(traderPositions[trader]);
        TranchePosition memory tranchePosition =
            loadTranchePosition(tranchePositions[traderPosition.trancheIdx]);

        //slither-disable-next-line uninitialized-local
        Position memory traderPos;

        // If the trader has no trancheShares we can take a simpler route here:
        // The trader will not own any asset nor stable from the tranche
        if (traderPosition.trancheShares == 0) {
            // The only stable the trader might own is stored in his position directly
            traderPos.stableExcludingFunding = traderPosition.stableExcludingFundingTranche;
            return (traderPos, tranchePosition, traderPosition.trancheIdx);
        }

        int256 trancheAsset = tranchePosition.position.asset;

        // used twice below optimizing for gas
        int256 traderTrancheShares = traderPosition.trancheShares;
        // used below multiple times optimizing for gas
        int256 trancheTotalShares = tranchePosition.totalShares;

        // Calculate how much of the tranches asset belongs to the trader
        FsUtils.Assert(trancheTotalShares >= traderPosition.trancheShares);
        FsUtils.Assert(trancheTotalShares > 0);
        traderPos.asset = (trancheAsset * traderTrancheShares) / trancheTotalShares;

        // Calculate how much of the tranches stable belongs to the trader
        int256 stableFromTranche =
            (tranchePosition.position.stableExcludingFunding * traderTrancheShares) /
                trancheTotalShares;

        // The total stable to the trader owns is his stable stored in the position
        // combined with the stable he owns from the tranchePosition
        traderPos.stableExcludingFunding =
            traderPosition.stableExcludingFundingTranche +
            stableFromTranche;

        tranchePosition.position.asset -= traderPos.asset;
        tranchePosition.position.stableExcludingFunding -= stableFromTranche;
        tranchePosition.totalShares -= traderPosition.trancheShares;

        return (traderPos, tranchePosition, traderPosition.trancheIdx);
    }

    function extractFromFunding(Position memory position, Funding memory fundingData) private pure {
        int256 asset = position.asset;
        int256 stable = 0;
        if (asset > 0) {
            FsUtils.Assert(fundingData.longAsset > 0);
            stable = (fundingData.longAccumulatedFunding * asset) / fundingData.longAsset;
            fundingData.longAccumulatedFunding -= stable;
            fundingData.longAsset -= asset;
        } else if (asset < 0) {
            FsUtils.Assert(fundingData.shortAsset > 0);
            stable = (fundingData.shortAccumulatedFunding * (-asset)) / fundingData.shortAsset;
            fundingData.shortAccumulatedFunding -= stable;
            fundingData.shortAsset -= (-asset);
        }
        position.stableExcludingFunding += stable;
    }

    function stableIncludingFunding(Position memory position, Funding memory fundingData)
        private
        pure
        returns (int256)
    {
        int256 asset = position.asset;
        int256 stable = 0;
        if (asset > 0) {
            FsUtils.Assert(fundingData.longAsset > 0);
            stable = (fundingData.longAccumulatedFunding * asset) / fundingData.longAsset;
        } else if (asset < 0) {
            FsUtils.Assert(fundingData.shortAsset > 0);
            stable = (fundingData.shortAccumulatedFunding * (-asset)) / fundingData.shortAsset;
        }
        return position.stableExcludingFunding + stable;
    }

    function insertInFunding(Position memory position, Funding memory fundingData) private pure {
        int256 asset = position.asset;
        int256 stable = 0;
        if (asset > 0) {
            if (fundingData.longAsset != 0) {
                stable = (fundingData.longAccumulatedFunding * asset) / fundingData.longAsset;
            }
            fundingData.longAccumulatedFunding += stable;
            fundingData.longAsset += asset;
        } else if (asset < 0) {
            if (fundingData.shortAsset != 0) {
                stable = (fundingData.shortAccumulatedFunding * (-asset)) / fundingData.shortAsset;
            }
            fundingData.shortAccumulatedFunding += stable;
            fundingData.shortAsset += (-asset);
        }
        position.stableExcludingFunding -= stable;
    }

    function insertPosition(
        Funding memory fundingData,
        address trader,
        Position memory traderPositionMem,
        int256 price
    ) private {
        // If the trader owns no asset we can skip all the computations below
        if (traderPositionMem.asset == 0) {
            traderPositions[trader] = Packing.EntranchedPosition(0, 0, 0);
            // Trades that have no asset can not have stable and will be paid out
            FsUtils.Assert(traderPositionMem.stableExcludingFunding == 0);
            return;
        }

        // Find the tranche the trade has to be stored in
        uint8 tranche = calculateTranche(traderPositionMem, price, fundingData);
        uint32 trancheIdx = trancheIds[tranche];
        Packing.TranchePosition storage packedTranchePosition = tranchePositions[trancheIdx];

        TranchePosition memory tranchePosition = loadTranchePosition(packedTranchePosition);

        // Over time tranches might inflate their shares (if the tranche got ADL'ed), which will lead to a precision
        // loss for the tranche. Before the precision loss becomes significant, we switch over to a new tranche.
        // We can see the precision loss for a trade by looking at the ratio of `tranche.totalShares` and
        // `tranche.position.asset`. The ratio for each tranche starts out at 1 to 1, and changes if the tranche gets
        // ADL'ed. Once the ratio has changed more then TRANCHE_INFLATION_MAX we create a new tranche and replace the
        // current one.
        int256 trancheAsset = tranchePosition.position.asset;
        int256 totalShares = tranchePosition.totalShares;
        FsUtils.Assert(totalShares >= 0);

        if (trancheIdx == 0 || totalShares > FsMath.sabs(trancheAsset) * TRANCHE_INFLATION_MAX) {
            // Either this is the first time a trader is put in this tranche or the tranche-transformation
            // has become numerically unstable. So create a new tranche position for this tranche.
            trancheIdx = ++nextTrancheIdx; // pre-increment to ensure tranche index 0 is never used
            trancheIds[tranche] = trancheIdx;
            packedTranchePosition = tranchePositions[trancheIdx];
            tranchePosition = loadTranchePosition(packedTranchePosition);

            trancheAsset = tranchePosition.position.asset;
            totalShares = tranchePosition.totalShares;
        }

        // Calculate how many shares of the tranche the trader is going to get.
        int256 trancheShares =
            trancheAsset == 0
                ? FsMath.sabs(traderPositionMem.asset)
                : (traderPositionMem.asset * totalShares) / trancheAsset;
        // Note that traderPos.asset and trancheAsset will have the same sign.
        FsUtils.Assert(trancheShares >= 0);

        // If there is any stable in the tranche we need to see how much of the stable the trader now gets from the
        // tranche so we can subtract it from the stable in their position.
        int256 trancheStable = tranchePosition.position.stableExcludingFunding;
        int256 deltaStable =
            totalShares == 0 ? int256(0) : (trancheStable * trancheShares) / totalShares;
        int256 traderStable = traderPositionMem.stableExcludingFunding - deltaStable;

        tranchePosition.position = Position(
            trancheAsset + traderPositionMem.asset,
            trancheStable + deltaStable
        );
        tranchePosition.totalShares = totalShares + trancheShares;
        storeEntranchedPosition(
            traderPositions[trader],
            EntranchedPosition(trancheShares, traderStable, trancheIdx)
        );
        storeTranchePosition(packedTranchePosition, tranchePosition);
    }

    function computeAssetAndStableToADL(
        Position memory traderPositionMem,
        int256 deltaAsset,
        bool isLiquidation,
        int256 oraclePrice,
        Funding memory fundingData
    )
        private
        view
        returns (
            int256,
            int256,
            bool
        )
    {
        // If the previous position of the trader was bankrupt or is being liquidated
        // we have to ADL the entire position
        int256 stable = stableIncludingFunding(traderPositionMem, fundingData);
        int256 traderPositionValue =
            FsMath.assetToStable(traderPositionMem.asset, oraclePrice) + stable;
        if (traderPositionValue < 0 || isLiquidation) {
            // If the position is bankrupt we ADL at the bankruptcy price, which is the best
            // price we can close the position without a loss for the pool.
            // TODO(gerben) Should we do this at liquidation too, because if it's not bankrupt
            // and thus has still positive value, ADL'ing at a price that makes it 0 value means
            // liquidator is not getting any money and the opposite traders get a very good deal.
            return (-traderPositionMem.asset, -stable, false);
        }

        int256 stableToADL = FsMath.assetToStable(-deltaAsset, oraclePrice);
        stableToADL -=
            (FsMath.sabs(stableToADL) * exchangeConfig.adlFeePercent) /
            FsMath.FIXED_POINT_BASED;

        return (deltaAsset, stableToADL, true);
    }

    function adlTrade(
        int256 deltaAsset,
        int256 stableBound,
        bool isLiquidation,
        int256 oraclePrice,
        Position memory traderPositionMem,
        Position memory ammPositionMem,
        Funding memory fundingData
    ) private returns (int256) {
        // regularClose is not a liquidation or bankruptcy.
        (int256 assetToADL, int256 stableToADL, bool regularClose) =
            computeAssetAndStableToADL(
                traderPositionMem,
                deltaAsset,
                isLiquidation,
                oraclePrice,
                fundingData
            );

        if (regularClose) {
            requireStableBound(stableBound, stableToADL);
        }

        uint8 offset = assetToADL > 0 ? 0 : 1;
        for (uint8 i = 0; i < MAX_TRANCHES; i++) {
            uint8 tranche = (MAX_TRANCHES - 1 - i) * 2 + offset;

            uint32 trancheIdx = trancheIds[tranche];

            (int256 assetADLInTranche, int256 stableADLInTranche) =
                adlTranche(
                    traderPositionMem,
                    tranchePositions[trancheIdx],
                    fundingData,
                    assetToADL,
                    stableToADL
                );

            assetToADL -= assetADLInTranche;
            stableToADL -= stableADLInTranche;

            if (assetADLInTranche != 0) {
                emit TrancheAutoDeleveraged(
                    tranche,
                    trancheIdx,
                    assetADLInTranche,
                    stableADLInTranche,
                    tranchePositions[trancheIdx].totalShares
                );
            }

            //slither-disable-next-line incorrect-equality
            if (assetToADL == 0) {
                FsUtils.Assert(stableToADL == 0);
                return 0;
            }
        }

        // If there is any assetToADL or stableToADL this means that we ran out of opposing trade
        // traderPositions to ADL and now liquidity providers take over the remainder of the position
        tradeInternal(traderPositionMem, ammPositionMem, fundingData, assetToADL, stableToADL);
        emit AmmAdl(assetToADL, stableToADL);

        return stableToADL;
    }

    function adlTranche(
        Position memory traderPosition,
        Packing.TranchePosition storage packedTranchePosition,
        Funding memory fundingData,
        int256 assetToADL,
        int256 stableToADL
    ) private returns (int256, int256) {
        int256 assetToADLInTranche;

        TranchePosition memory tranchePosition = loadTranchePosition(packedTranchePosition);

        int256 assetInTranche = tranchePosition.position.asset;

        if (assetToADL < 0) {
            assetToADLInTranche = assetInTranche > assetToADL ? assetInTranche : assetToADL;
        } else {
            assetToADLInTranche = assetInTranche > assetToADL ? assetToADL : assetInTranche;
        }

        int256 stableToADLInTranche = (stableToADL * assetToADLInTranche) / assetToADL;

        tradeInternal(
            traderPosition,
            tranchePosition.position,
            fundingData,
            assetToADLInTranche,
            stableToADLInTranche
        );

        storeTranchePosition(packedTranchePosition, tranchePosition);

        return (assetToADLInTranche, stableToADLInTranche);
    }

    function updateFunding(
        Position memory ammPositionMem,
        Funding memory funding,
        uint256 time,
        int256 price
    ) private view returns (int256 timeFee, int256 dfrFee) {
        if (time <= funding.lastUpdatedTimestamp) {
            // Normally time < lastUpdatedTimestamp cannot occur, only
            // time == lastUpdatedTimestamp as block timestamps are non-decreasing.
            // However we allow time equals 0 for convenience in the view functions
            // when callers are not interested in the effect of funding on the position.
            return (0, 0);
        }

        FsUtils.Assert(time > funding.lastUpdatedTimestamp); // See above condition
        // slither-disable-next-line safe-cast
        int256 deltaTime = int256(time - funding.lastUpdatedTimestamp);

        funding.lastUpdatedTimestamp = time;

        timeFee = calculateTimeFee(deltaTime, funding.longAsset, price);
        dfrFee = calculateDFR(deltaTime, ammPosition.asset, price);

        // Writing both asset changes back here once, to optimize for gas
        funding.longAccumulatedFunding -= timeFee - dfrFee;
        funding.shortAccumulatedFunding -= timeFee + dfrFee;
        // Note both longs and shorts pay time fee (hence factor of 2)
        timeFee *= 2;
        ammPositionMem.stableExcludingFunding += timeFee;
    }

    /// @notice Calculates the DFR fee to pay in stable. The result is positive when shorts pay longs
    /// (ie, there are more shorts than longs), and negative otherwise.
    /// @param deltaTime period of time for which to compute the DFR fee.
    /// @param ammAsset The asset position of the AMM, which is the oposite to the overall traders position in the
    /// exchange. If ammAsset is positive (ie, AMM is long), then the traders in the exchange are short, and viceversa.
    /// @param assetPrice DFR is charged in stable using the `assetPrice` to convert from asset.
    function calculateDFR(
        int256 deltaTime,
        int256 ammAsset,
        int256 assetPrice
    ) private view returns (int256) {
        int256 dfrRate = exchangeConfig.dfrRate;
        return
            (FsMath.assetToStable(ammAsset, assetPrice) * dfrRate * deltaTime) /
            FsMath.FIXED_POINT_BASED;
    }

    /// @notice Calculates the Time fee to pay in stable. The result is positive the total exchange position is long
    /// and negative otherwise.
    /// @param deltaTime period of time for which to compute the time fee.
    /// @param totalAsset The asset position of the traders in the exchange.
    /// @param assetPrice Time fee is charged in stable using the `assetPrice` to convert from asset.
    function calculateTimeFee(
        int256 deltaTime,
        int256 totalAsset,
        int256 assetPrice
    ) private view returns (int256) {
        int256 timeFee = exchangeConfig.timeFee;
        return
            (FsMath.assetToStable(totalAsset, assetPrice) * deltaTime * timeFee) /
            FsMath.FIXED_POINT_BASED;
    }

    function canBeLiquidated(
        int256 asset,
        int256 stable,
        int256 assetPrice
    ) private view returns (bool) {
        if (asset == 0) {
            return stable < 0;
        }

        int256 assetInStable = FsMath.assetToStable(asset, assetPrice);
        int256 collateral = assetInStable + stable;

        // Safe cast does not evaluate compile time constants yet. `type(int256).max` is within the
        // `uint256` type range.
        // slither-disable-next-line safe-cast
        FsUtils.Assert(
            0 < exchangeConfig.minCollateral &&
                exchangeConfig.minCollateral <= uint256(type(int256).max)
        );
        // `exchangeConfig.minCollateral` is checked in `setExchangeConfig` to be within range for
        // `int256`.
        // slither-disable-next-line safe-cast
        if (collateral < int256(exchangeConfig.minCollateral)) {
            return true;
        }
        // We check for `collateral` to be equal or above `exchangeConfig.minCollateral`.
        // `exchangeConfig.minCollateral` is strictly positive, so it is safe to convert
        // `collateral` to `uint256`.  And it is safe to divide, as we know the number is not going
        // to be zero.  If `exchangeConfig.minCollateral` will allow `0` as a valid value, we need
        // an additions check for `collateral` to be equal to `0`.
        //
        // slither-disable-next-line safe-cast
        uint256 leverage = FsMath.calculateLeverage(asset, stable, assetPrice);
        return leverage >= exchangeConfig.maxLeverage;
    }

    function loadFunding() private view returns (Funding memory) {
        return
            Funding(
                packedFundingData.longAccumulatedFunding,
                packedFundingData.openAsset,
                packedFundingData.shortAccumulatedFunding,
                packedFundingData.openAsset,
                packedFundingData.lastUpdatedTimestamp
            );
    }

    function storeFunding(Funding memory fundingData) private {
        FsUtils.Assert(fundingData.longAsset == fundingData.shortAsset);
        packedFundingData.openAsset = int128(fundingData.longAsset);
        packedFundingData.longAccumulatedFunding = int128(fundingData.longAccumulatedFunding);
        packedFundingData.shortAccumulatedFunding = int128(fundingData.shortAccumulatedFunding);
        packedFundingData.lastUpdatedTimestamp = uint128(fundingData.lastUpdatedTimestamp);
    }

    function loadPosition(Packing.Position storage packedPosition)
        private
        view
        returns (Position memory)
    {
        return Position(packedPosition.asset, packedPosition.stableExcludingFunding);
    }

    function storePosition(Packing.Position storage packedPosition, Position memory position)
        private
    {
        packedPosition.asset = int128(position.asset);
        packedPosition.stableExcludingFunding = int128(position.stableExcludingFunding);
    }

    function loadTranchePosition(Packing.TranchePosition storage packedTranchePosition)
        private
        view
        returns (TranchePosition memory)
    {
        return
            TranchePosition(
                loadPosition(packedTranchePosition.position),
                packedTranchePosition.totalShares
            );
    }

    function storeTranchePosition(
        Packing.TranchePosition storage packedTranchePosition,
        TranchePosition memory tranchePosition
    ) private {
        storePosition(packedTranchePosition.position, tranchePosition.position);
        packedTranchePosition.totalShares = tranchePosition.totalShares;
    }

    function loadEntranchedPosition(Packing.EntranchedPosition storage packedEntranchedPosition)
        private
        view
        returns (EntranchedPosition memory)
    {
        return
            EntranchedPosition(
                packedEntranchedPosition.shares,
                packedEntranchedPosition.stableExcludingFundingTranche,
                packedEntranchedPosition.trancheIdx
            );
    }

    function storeEntranchedPosition(
        Packing.EntranchedPosition storage packedEntranchedPosition,
        EntranchedPosition memory entranchedPosition
    ) private {
        packedEntranchedPosition.shares = int112(entranchedPosition.trancheShares);
        packedEntranchedPosition.stableExcludingFundingTranche = int112(
            entranchedPosition.stableExcludingFundingTranche
        );
        packedEntranchedPosition.trancheIdx = entranchedPosition.trancheIdx;
    }

    /// @inheritdoc IExchangeLedger
    function setExchangeConfig(ExchangeConfig calldata config) external override onlyOwner {
        if (keccak256(abi.encode(config)) == keccak256(abi.encode(exchangeConfig))) {
            return;
        }

        // We use `minCollateral` in `int256` calculations.  In particular, in `canBeLiquidated()`
        // we expect `minCollateral` to be positive.
        //
        // `canBeLiquidated()` relies on `minCollateral` to be non-zero.  If `minCollateral` is `0`
        // and a position slides to have `0` in their `collateral` it becomes unliquidatable, due to
        // a division by zero in `canBeLiquidated()`.
        //
        // slither-disable-next-line safe-cast
        require(
            0 < config.minCollateral && config.minCollateral <= uint256(type(int256).max),
            "minCollateral outside valid range"
        );

        emit ExchangeConfigChanged(exchangeConfig, config);

        exchangeConfig = config;
    }

    /// @inheritdoc IExchangeLedger
    function setExchangeState(ExchangeState _exchangeState, int256 _pausePrice)
        external
        override
        onlyOwner
    {
        _pausePrice = _exchangeState == ExchangeState.PAUSED ? _pausePrice : int256(0);

        if (exchangeState == _exchangeState && pausePrice == _pausePrice) {
            return;
        }

        emit ExchangeStateChanged(exchangeState, pausePrice, _exchangeState, _pausePrice);
        pausePrice = _pausePrice;
        exchangeState = _exchangeState;
    }

    /// @inheritdoc IExchangeLedger
    function setHook(address _hook) external override onlyOwner {
        if (address(hook) == _hook) {
            return;
        }

        emit ExchangeHookAddressChanged(address(hook), _hook);
        hook = IExchangeHook(_hook);
    }

    /// @inheritdoc IExchangeLedger
    function setAmm(address _amm) external override onlyOwner {
        if (address(amm) == _amm) {
            return;
        }

        emit AmmAddressChanged(address(amm), _amm);
        // slither-disable-next-line missing-zero-check
        amm = IAmm(FsUtils.nonNull(_amm));
    }

    /// @inheritdoc IExchangeLedger
    function setTradeRouter(address _tradeRouter) external override onlyOwner {
        if (address(tradeRouter) == _tradeRouter) {
            return;
        }

        emit TradeRouterAddressChanged(address(tradeRouter), _tradeRouter);
        // slither-disable-next-line missing-zero-check
        tradeRouter = FsUtils.nonNull(_tradeRouter);
    }
}