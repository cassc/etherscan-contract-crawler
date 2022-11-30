//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

import {IPool} from "@yield-protocol/yieldspace-tv/src/interfaces/IPool.sol";
import {ILadle} from "@yield-protocol/vault-v2/contracts/interfaces/ILadle.sol";
import {ICauldron} from "@yield-protocol/vault-v2/contracts/interfaces/ICauldron.sol";
import {IFYToken} from "@yield-protocol/vault-v2/contracts/interfaces/IFYToken.sol";
import {DataTypes} from "@yield-protocol/vault-v2/contracts/interfaces/DataTypes.sol";
import {IContangoLadle} from "@yield-protocol/vault-v2/contracts/other/contango/interfaces/IContangoLadle.sol";

import "../UniswapV3Handler.sol";
import "./YieldUtils.sol";
import {ConfigStorageLib, StorageLib, YieldStorageLib} from "../../libraries/StorageLib.sol";
import "../SlippageLib.sol";
import "../../libraries/DataTypes.sol";
import "../../libraries/ErrorLib.sol";
import "../../libraries/CodecLib.sol";
import "../../libraries/PositionLib.sol";
import "../../libraries/TransferLib.sol";
import {ExecutionProcessorLib} from "../../ExecutionProcessorLib.sol";

library Yield {
    using YieldUtils for *;
    using SignedMath for int256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using CodecLib for uint256;
    using PositionLib for PositionId;
    using TransferLib for IERC20Metadata;

    event ContractTraded(Symbol indexed symbol, address indexed trader, PositionId indexed positionId, Fill fill);
    event CollateralAdded(
        Symbol indexed symbol, address indexed trader, PositionId indexed positionId, uint256 amount, uint256 cost
    );
    event CollateralRemoved(
        Symbol indexed symbol, address indexed trader, PositionId indexed positionId, uint256 amount, uint256 cost
    );

    uint128 public constant BORROWING_BUFFER = 5;

    function createPosition(
        Symbol symbol,
        address trader,
        uint256 quantity,
        uint256 limitCost,
        uint256 collateral,
        address payer,
        uint256 lendingLiquidity
    ) external returns (PositionId positionId) {
        if (quantity == 0) {
            revert InvalidQuantity(int256(quantity));
        }

        positionId = ConfigStorageLib.getPositionNFT().mint(trader);
        positionId.validatePayer(payer, trader);

        StorageLib.getPositionInstrument()[positionId] = symbol;
        Instrument memory instrument = _createPosition(symbol, positionId);

        _open(symbol, positionId, trader, instrument, quantity, limitCost, int256(collateral), payer, lendingLiquidity);
    }

    function modifyPosition(
        PositionId positionId,
        int256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) external {
        if (quantity == 0) {
            revert InvalidQuantity(quantity);
        }

        (uint256 openQuantity, address trader, Symbol symbol, Instrument memory instrument) =
            positionId.loadActivePosition();
        if (collateral > 0) {
            positionId.validatePayer(payerOrReceiver, trader);
        }

        if (quantity < 0 && uint256(-quantity) > openQuantity) {
            revert InvalidPositionDecrease(positionId, quantity, openQuantity);
        }

        if (quantity > 0) {
            _open(
                symbol,
                positionId,
                trader,
                instrument,
                uint256(quantity),
                limitCost,
                collateral,
                payerOrReceiver,
                lendingLiquidity
            );
        } else {
            _close(
                symbol,
                positionId,
                trader,
                instrument,
                uint256(-quantity),
                limitCost,
                collateral,
                payerOrReceiver,
                lendingLiquidity
            );
        }

        if (quantity < 0 && uint256(-quantity) == openQuantity) {
            _deletePosition(positionId);
        }
    }

    function collateralBought(bytes12 vaultId, uint256 ink, uint256 art) external {
        PositionId positionId = PositionId.wrap(uint96(vaultId));
        ExecutionProcessorLib.liquidatePosition(
            StorageLib.getPositionInstrument()[positionId],
            positionId,
            ConfigStorageLib.getPositionNFT().positionOwner(positionId),
            ink,
            art
        );
    }

    function _createPosition(Symbol symbol, PositionId positionId) private returns (Instrument memory instrument) {
        YieldInstrument storage yieldInsturment;
        (instrument, yieldInsturment) = symbol.loadInstrument();

        // solhint-disable-next-line not-rely-on-time
        if (instrument.maturity < block.timestamp) {
            // solhint-disable-next-line not-rely-on-time
            revert InstrumentExpired(symbol, instrument.maturity, block.timestamp);
        }

        YieldStorageLib.getLadle().deterministicBuild(
            positionId.toVaultId(), yieldInsturment.quoteId, yieldInsturment.baseId
        );
    }

    function _deletePosition(PositionId positionId) private {
        positionId.deletePosition();
        YieldStorageLib.getLadle().destroy(positionId.toVaultId());
    }

    function _open(
        Symbol symbol,
        PositionId positionId,
        address trader,
        Instrument memory instrument,
        uint256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) private {
        YieldInstrument storage yieldInstrument = YieldStorageLib.getInstruments()[symbol];
        address receiver = lendingLiquidity < quantity ? address(this) : address(yieldInstrument.basePool);

        // Use a flash swap to buy enough base to hedge the position, pay directly to the pool where we'll lend it
        _flashBuyHedge(
            instrument,
            yieldInstrument,
            UniswapV3Handler.CallbackInfo({
                symbol: symbol,
                positionId: positionId,
                trader: trader,
                limitCost: limitCost,
                payerOrReceiver: payerOrReceiver,
                open: true,
                lendingLiquidity: lendingLiquidity
            }),
            quantity,
            int256(collateral),
            receiver
        );
    }

    /// @dev Second step of trading, this executes on the back of the flash swap callback,
    /// it will pay part of the swap by using the trader collateral,
    /// then will borrow the rest from the lending protocol. Fill cost == swap cost + loan interest.
    /// @param callback Info collected before the flash swap started
    function completeOpen(UniswapV3Handler.Callback memory callback) internal {
        YieldInstrument storage yieldInstrument = YieldStorageLib.getInstruments()[callback.info.symbol];

        // Cast is safe as the number was previously casted as uint128
        uint128 ink = uint128(callback.fill.size);

        // Lend the base we just flash bought
        _buyFYToken({
            pool: yieldInstrument.basePool,
            underlying: callback.instrument.base,
            fyToken: yieldInstrument.baseFyToken,
            to: YieldStorageLib.getJoins()[yieldInstrument.baseId], // send the (fy)Base to the join so it can be used as collateral for borrowing
            fyTokenOut: ink,
            lendingLiquidity: callback.info.lendingLiquidity,
            excessExpected: false
        });

        // Use the payer collateral (if any) to pay part/all of the flash swap
        if (callback.fill.collateral > 0) {
            // Trader can contribute up to the spot cost
            callback.fill.collateral = SignedMath.min(callback.fill.collateral, int256(callback.fill.hedgeCost));
            callback.instrument.quote.transferOut(
                callback.info.payerOrReceiver, msg.sender, uint256(callback.fill.collateral)
            );
        }

        uint128 amountToBorrow = (int256(callback.fill.hedgeCost) - callback.fill.collateral).toUint256().toUint128();
        uint128 art;

        // If the collateral wasn't enough to cover the whole trade
        if (amountToBorrow != 0) {
            // Math is not exact anymore with the PoolEuler, so we need to borrow a bit more
            amountToBorrow += BORROWING_BUFFER;
            // How much debt at future value (art) do I need to take on in order to get enough cash at present value (remainder)
            art = yieldInstrument.quotePool.buyBasePreview(amountToBorrow);
        }

        // Deposit collateral (ink) and take on debt if necessary (art)
        YieldStorageLib.getLadle().pour(
            callback.info.positionId.toVaultId(), // Vault that will issue the debt & store the collateral
            address(yieldInstrument.quotePool), // If taking any debt, send it to the pool so it can be sold
            int128(ink), // Use the fyTokens we bought using the flash swap as ink (collateral)
            int128(art) // Amount to borrow in future value
        );

        address sendBorrowedFundsTo;

        if (callback.fill.collateral < 0) {
            // We need to keep the borrowed funds in this contract so we can pay both the trader and uniswap
            sendBorrowedFundsTo = address(this);
            // Cost is spot + financing costs
            callback.fill.cost = callback.fill.hedgeCost + (art - amountToBorrow);
        } else {
            // We can pay to uniswap directly as it's the only reason we are borrowing for
            sendBorrowedFundsTo = msg.sender;
            // Cost is spot + debt + financing costs
            callback.fill.cost = art + uint256(callback.fill.collateral);
        }

        SlippageLib.requireCostBelowTolerance(callback.fill.cost, callback.info.limitCost);

        if (amountToBorrow != 0) {
            // Sell the fyTokens for actual cash
            yieldInstrument.quotePool.buyBase(
                sendBorrowedFundsTo,
                amountToBorrow, // Amount to borrow in present value
                art // Max amount to pay (redundant, but required by the API)
            );
        }

        // Pay uniswap if necessary
        if (sendBorrowedFundsTo == address(this)) {
            callback.instrument.quote.transferOut(address(this), msg.sender, callback.fill.hedgeCost);
        }

        ExecutionProcessorLib.increasePosition(
            callback.info.symbol,
            callback.info.positionId,
            callback.info.trader,
            callback.fill.size,
            callback.fill.cost,
            callback.fill.collateral,
            callback.instrument.quote,
            callback.info.payerOrReceiver,
            yieldInstrument.minQuoteDebt
        );

        emit ContractTraded(callback.info.symbol, callback.info.trader, callback.info.positionId, callback.fill);
    }

    function _close(
        Symbol symbol,
        PositionId positionId,
        address trader,
        Instrument memory instrument,
        uint256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) private {
        // Execute a flash swap to undo the hedge
        _flashSellHedge(
            instrument,
            YieldStorageLib.getInstruments()[symbol],
            UniswapV3Handler.CallbackInfo({
                symbol: symbol,
                positionId: positionId,
                limitCost: limitCost,
                trader: trader,
                payerOrReceiver: payerOrReceiver,
                open: false,
                lendingLiquidity: lendingLiquidity
            }),
            quantity,
            collateral,
            address(this) // We must receive the funds ourselves cause the TV pools will consume them all otherwise
        );
    }

    /// @dev Second step to reduce/close a position. This executes on the back of the flash swap callback,
    /// then it will repay debt using the proceeds from the flash swap and deal with any excess appropriately.
    /// @param callback Info collected before the flash swap started
    function completeClose(UniswapV3Handler.Callback memory callback) internal {
        YieldInstrument storage yieldInstrument = YieldStorageLib.getInstruments()[callback.info.symbol];
        DataTypes.Balances memory balances =
            YieldStorageLib.getCauldron().balances(callback.info.positionId.toVaultId());
        bool fullyClosing = callback.fill.size == balances.ink;
        int128 art;

        // If there's any debt to repay
        if (balances.art != 0) {
            // Use the quote we just bought to buy/mint fyTokens to reduce the debt and free up the amount we owe for the flash loan
            if (fullyClosing) {
                // If we're closing, pay all debt
                art = -int128(balances.art);
                // Buy the exact amount of (fy)Quote we owe (art) using the money from the flash swap (money was sent directly to the quotePool).
                // Send the tokens to the fyToken contract so they can be burnt
                // Cost == swap cost + pnl of cancelling the debt
                uint128 baseIn = _buyFYToken({
                    pool: yieldInstrument.quotePool,
                    underlying: callback.instrument.quote,
                    fyToken: yieldInstrument.quoteFyToken,
                    to: address(yieldInstrument.quoteFyToken),
                    fyTokenOut: balances.art,
                    lendingLiquidity: callback.info.lendingLiquidity,
                    excessExpected: true
                });
                callback.fill.cost = callback.fill.hedgeCost + (balances.art - baseIn);
            } else {
                // Can't withdraw more than what we got from UNI
                if (callback.fill.collateral < 0) {
                    callback.fill.collateral =
                        SignedMath.max(callback.fill.collateral, -int256(callback.fill.hedgeCost));
                }

                int256 quoteUsedToRepayDebt = callback.fill.collateral + int256(callback.fill.hedgeCost);

                if (quoteUsedToRepayDebt > 0) {
                    // If the user is depositing, take the necessary tokens from the trader
                    if (callback.fill.collateral > 0) {
                        callback.instrument.quote.transferOut({
                            payer: callback.info.payerOrReceiver,
                            to: address(this),
                            amount: uint256(callback.fill.collateral)
                        });
                    }

                    // Under normal circumstances, send the required funds to the pool
                    if (uint256(quoteUsedToRepayDebt) < callback.info.lendingLiquidity) {
                        callback.instrument.quote.transferOut({
                            payer: address(this),
                            to: address(yieldInstrument.quotePool),
                            amount: uint256(quoteUsedToRepayDebt)
                        });
                    }

                    // Buy fyTokens with the available tokens
                    art = -int128(
                        _sellBase({
                            pool: yieldInstrument.quotePool,
                            underlying: callback.instrument.quote,
                            fyToken: yieldInstrument.quoteFyToken,
                            to: address(yieldInstrument.quoteFyToken),
                            availableBase: uint256(quoteUsedToRepayDebt).toUint128(),
                            lendingLiquidity: callback.info.lendingLiquidity
                        })
                    );
                }

                callback.fill.cost = (-(callback.fill.collateral + art)).toUint256();
            }
        } else {
            // Given there's no debt, the cost is the hedgeCost
            callback.fill.cost = callback.fill.hedgeCost;
        }

        SlippageLib.requireCostAboveTolerance(callback.fill.cost, callback.info.limitCost);

        // Burn debt and withdraw collateral from Yield, send the collateral directly to the basePool so it can be sold
        YieldStorageLib.getLadle().pour(
            callback.info.positionId.toVaultId(),
            address(yieldInstrument.basePool),
            -int256(callback.fill.size).toInt128(),
            art
        );
        // Sell collateral (ink) to pay for the flash swap, the amount of ink was pre-calculated to obtain the exact cost of the swap
        yieldInstrument.basePool.sellFYToken(msg.sender, uint128(callback.fill.hedgeSize));

        emit ContractTraded(callback.info.symbol, callback.info.trader, callback.info.positionId, callback.fill);

        if (fullyClosing) {
            ExecutionProcessorLib.closePosition(
                callback.info.symbol,
                callback.info.positionId,
                callback.info.trader,
                callback.fill.cost,
                callback.instrument.quote,
                callback.info.payerOrReceiver
            );
        } else {
            ExecutionProcessorLib.decreasePosition(
                callback.info.symbol,
                callback.info.positionId,
                callback.info.trader,
                callback.fill.size,
                callback.fill.cost,
                callback.fill.collateral,
                callback.instrument.quote,
                callback.info.payerOrReceiver,
                yieldInstrument.minQuoteDebt
            );
        }
    }

    // ============== Physical delivery ==============

    function deliver(PositionId positionId, address payer, address to) external {
        address trader = positionId.positionOwner();
        positionId.validatePayer(payer, trader);

        (, Symbol symbol, Instrument memory instrument) = positionId.validateExpiredPosition();

        _deliver(symbol, positionId, trader, instrument, payer, to);

        _deletePosition(positionId);
    }

    function _deliver(
        Symbol symbol,
        PositionId positionId,
        address trader,
        Instrument memory instrument,
        address payer,
        address to
    ) private {
        YieldInstrument storage yieldInstrument = YieldStorageLib.getInstruments()[symbol];
        IFYToken baseFyToken = yieldInstrument.baseFyToken;
        ILadle ladle = YieldStorageLib.getLadle();
        ICauldron cauldron = YieldStorageLib.getCauldron();
        DataTypes.Balances memory balances = cauldron.balances(positionId.toVaultId());

        uint256 requiredQuote;
        if (balances.art != 0) {
            bytes6 quoteId = yieldInstrument.quoteId;

            // we need to cater for the interest rate accrued after maturity
            requiredQuote = cauldron.debtToBase(quoteId, balances.art);

            // Send the requiredQuote to the Join
            instrument.quote.transferOut(payer, address(ladle.joins(cauldron.series(quoteId).baseId)), requiredQuote);

            ladle.close(
                positionId.toVaultId(),
                address(baseFyToken), // Send ink to be redeemed on the FYToken contract
                -int128(balances.ink), // withdraw ink
                -int128(balances.art) // repay art
            );
        } else {
            ladle.pour(
                positionId.toVaultId(),
                address(baseFyToken), // Send ink to be redeemed on the FYToken contract
                -int128(balances.ink), // withdraw ink
                0 // no debt to repay
            );
        }

        ExecutionProcessorLib.deliverPosition(
            symbol,
            positionId,
            trader,
            // Burn fyTokens in exchange for underlying, send underlying to `to`
            baseFyToken.redeem(to, balances.ink),
            requiredQuote,
            payer,
            instrument.quote,
            to
        );
    }

    // ============== Collateral management ==============

    function modifyCollateral(
        PositionId positionId,
        int256 collateral,
        uint256 slippageTolerance,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) external {
        (, address trader, Symbol symbol, Instrument memory instrument) = positionId.loadActivePosition();

        if (collateral > 0) {
            positionId.validatePayer(payerOrReceiver, trader);
            _addCollateral(
                symbol,
                positionId,
                trader,
                instrument,
                uint256(collateral),
                slippageTolerance,
                payerOrReceiver,
                lendingLiquidity
            );
        }
        if (collateral < 0) {
            _removeCollateral(symbol, positionId, trader, uint256(-collateral), slippageTolerance, payerOrReceiver);
        }
    }

    function _addCollateral(
        Symbol symbol,
        PositionId positionId,
        address trader,
        Instrument memory instrument,
        uint256 collateral,
        uint256 slippageTolerance,
        address payer,
        uint256 lendingLiquidity
    ) private {
        YieldInstrument storage yieldInstrument = YieldStorageLib.getInstruments()[symbol];
        IPool quotePool = yieldInstrument.quotePool;

        address to = collateral > lendingLiquidity ? address(this) : address(quotePool);
        if (to != payer) {
            // Collect the new collateral from the payer and send wherever's appropriate
            instrument.quote.transferOut({payer: payer, to: to, amount: collateral});
        }

        // Sell the collateral and get as much (fy)Quote (art) as possible
        uint256 art = _sellBase({
            pool: quotePool,
            underlying: instrument.quote,
            fyToken: yieldInstrument.quoteFyToken,
            to: address(yieldInstrument.quoteFyToken), // Send the (fy)Quote to itself so it can be burnt
            availableBase: collateral.toUint128(),
            lendingLiquidity: lendingLiquidity
        });

        SlippageLib.requireCostAboveTolerance(art, slippageTolerance);

        // Use the (fy)Quote (art) we bought to burn debt on the vault
        YieldStorageLib.getLadle().pour(
            positionId.toVaultId(),
            address(0), // We're not taking new debt, so no need to pass an address
            0, // We're not changing the collateral
            -int256(art).toInt128() // We burn all the (fy)Quote we just bought
        );

        // The interest pnl is reflected on the position cost
        int256 cost = -int256(art - collateral);

        // cast to int is safe as we prev casted to uint128
        ExecutionProcessorLib.updateCollateral(symbol, positionId, trader, cost, int256(collateral));

        emit CollateralAdded(symbol, trader, positionId, collateral, art);
    }

    function _removeCollateral(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 collateral,
        uint256 slippageTolerance,
        address to
    ) private {
        // Borrow whatever the trader wants to withdraw
        uint128 art = YieldStorageLib.getLadle().serve(
            positionId.toVaultId(),
            to, // Send the borrowed funds directly
            0, // We don't deposit any new collateral
            collateral.toUint128(), // Amount to borrow
            type(uint128).max // We don't need slippage control here, we have a general check below
        );

        SlippageLib.requireCostBelowTolerance(art, slippageTolerance);

        // The interest pnl is reflected on the position cost
        int256 cost = int256(art - collateral);

        // cast to int is safe as we prev casted to uint128
        ExecutionProcessorLib.updateCollateral(symbol, positionId, trader, cost, -int256(collateral));

        emit CollateralRemoved(symbol, trader, positionId, collateral, art);
    }

    // ============== Uniswap functions ==============

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        UniswapV3Handler.uniswapV3SwapCallback(amount0Delta, amount1Delta, data, _onUniswapCallback);
    }

    function _onUniswapCallback(UniswapV3Handler.Callback memory callback) internal {
        if (callback.info.open) {
            completeOpen(callback);
        } else {
            completeClose(callback);
        }
    }

    function _flashBuyHedge(
        Instrument memory instrument,
        YieldInstrument storage yieldInstrument,
        UniswapV3Handler.CallbackInfo memory callbackInfo,
        uint256 quantity,
        int256 collateral,
        address to
    ) private {
        UniswapV3Handler.Callback memory callback;

        callback.fill.size = quantity;
        callback.fill.collateral = collateral;
        callback.fill.hedgeSize =
            _buyFYTokenPreview(yieldInstrument.basePool, quantity.toUint128(), callbackInfo.lendingLiquidity);

        callback.info = callbackInfo;

        UniswapV3Handler.flashSwap(callback, -int256(callback.fill.hedgeSize), instrument, false, to);
    }

    /// @dev calculates the amount of base ccy to sell based on the traded quantity and executes a flash swap
    function _flashSellHedge(
        Instrument memory instrument,
        YieldInstrument storage yieldInstrument,
        UniswapV3Handler.CallbackInfo memory callbackInfo,
        uint256 quantity,
        int256 collateral,
        address to
    ) private {
        UniswapV3Handler.Callback memory callback;

        callback.fill.size = quantity;
        callback.fill.collateral = collateral;
        // Calculate how much base we'll get by selling the trade quantity
        callback.fill.hedgeSize = yieldInstrument.basePool.sellFYTokenPreview(quantity.toUint128());

        callback.info = callbackInfo;

        UniswapV3Handler.flashSwap(callback, int256(callback.fill.hedgeSize), instrument, true, to);
    }

    // ============== Private functions ==============

    function _sellBase(
        IPool pool,
        IERC20Metadata underlying,
        IFYToken fyToken,
        address to,
        uint128 availableBase,
        uint256 lendingLiquidity
    ) private returns (uint128 fyTokenOut) {
        if (availableBase > lendingLiquidity) {
            uint128 maxBaseIn = uint128(lendingLiquidity);
            fyTokenOut = pool.sellBasePreviewZero(maxBaseIn);
            if (fyTokenOut > 0) {
                // Transfer max amount that can be sold
                underlying.transferOut(address(this), address(pool), maxBaseIn);
                // Sell limited amount to the pool
                fyTokenOut = pool.sellBase(to, fyTokenOut);
            } else {
                maxBaseIn = 0;
            }

            // Amount to mint 1:1
            fyTokenOut += _forceLend(underlying, fyToken, to, availableBase - maxBaseIn);
        } else {
            fyTokenOut = pool.sellBase(to, availableBase);
        }
    }

    function _buyFYTokenPreview(IPool pool, uint128 fyTokenOut, uint256 lendingLiquidity)
        private
        view
        returns (uint128 baseIn)
    {
        if (fyTokenOut > lendingLiquidity) {
            uint128 maxFYTokenOut = uint128(lendingLiquidity);
            baseIn = maxFYTokenOut == 0
                ? fyTokenOut
                : fyTokenOut - maxFYTokenOut + pool.buyFYTokenPreviewFixed(maxFYTokenOut);
        } else {
            baseIn = pool.buyFYTokenPreviewFixed(fyTokenOut);
        }
    }

    function _buyFYToken(
        IPool pool,
        IERC20Metadata underlying,
        IFYToken fyToken,
        address to,
        uint128 fyTokenOut,
        uint256 lendingLiquidity,
        bool excessExpected
    ) private returns (uint128 baseIn) {
        if (fyTokenOut > lendingLiquidity) {
            uint128 maxFYTokenOut = uint128(lendingLiquidity);

            if (maxFYTokenOut > 0) {
                // Send required funds to the pool
                baseIn = uint128(
                    underlying.transferOut({
                        payer: address(this),
                        to: address(pool),
                        amount: pool.buyFYTokenPreviewFixed(maxFYTokenOut)
                    })
                );

                pool.buyFYToken(to, maxFYTokenOut, type(uint128).max);
            }

            // Amount to mint 1:1
            baseIn += _forceLend(underlying, fyToken, to, fyTokenOut - maxFYTokenOut);
        } else {
            if (excessExpected) {
                // Send required funds to the pool
                baseIn = uint128(
                    underlying.transferOut({
                        payer: address(this),
                        to: address(pool),
                        amount: pool.buyFYTokenPreviewFixed(fyTokenOut)
                    })
                );

                pool.buyFYToken(to, fyTokenOut, type(uint128).max);
            } else {
                baseIn = pool.buyFYToken(to, fyTokenOut, type(uint128).max);
            }
        }
    }

    function _forceLend(IERC20Metadata underlying, IFYToken fyToken, address to, uint128 toMint)
        internal
        returns (uint128)
    {
        underlying.transferOut(address(this), address(fyToken.join()), toMint);
        fyToken.mintWithUnderlying(to, toMint);
        return toMint;
    }
}