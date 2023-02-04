//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";

import "solmate/src/tokens/WETH.sol";

import "../../libraries/CodecLib.sol";
import "../../libraries/PositionLib.sol";
import "../../libraries/ProxyLib.sol";
import "../../libraries/TransferLib.sol";

import "../../ExecutionProcessorLib.sol";
import "../SlippageLib.sol";
import "../UniswapV3Handler.sol";

import "./NotionalUtils.sol";
import "./ContangoVaultProxyDeployer.sol";

// solhint-disable not-rely-on-time
library Notional {
    using CodecLib for uint256;
    using NotionalUtils for *;
    using PositionLib for PositionId;
    using ProxyLib for PositionId;
    using SafeCast for *;
    using SignedMath for int256;
    using TransferLib for ERC20;

    // TODO alfredo - this will have a lot in common with Yield.sol, evaluate after implementation what can be shared
    // TODO alfredo - natspec

    // go around stack too deep issues
    struct OpenEnterVaultParams {
        PositionId positionId;
        ContangoVault vault;
        uint256 maturity;
        uint256 fCashToBorrow;
        uint256 amountToBorrow;
        uint256 fCashLend;
        uint256 lendAmount;
    }

    struct CloseExitVaultParams {
        address proxy;
        ContangoVault vault;
        PositionId positionId;
        uint256 fCashLentToRedeem;
        uint256 fCashBorrowedToBurn;
        uint256 repaymentAmount;
        uint256 withdrawAmount;
        bool isQuoteWeth;
    }

    struct AddCollateralExitVaultParams {
        address proxy;
        ContangoVault vault;
        PositionId positionId;
        uint256 fCashBorrowedToBurn;
        uint256 collateral;
        bool isQuoteWeth;
    }

    struct RemoveCollateralEnterVaultParams {
        PositionId positionId;
        ContangoVault vault;
        uint256 maturity;
        uint256 fCashToBorrow;
        uint256 collateral;
        address receiver;
        uint256 quotePrecision;
    }

    struct SettleVaultAccountParams {
        ContangoVault vault;
        address proxy;
        uint256 maturity;
        uint256 repaymentAmount;
        uint256 withdrawAmount;
        address to;
        bool isQuoteWeth;
    }

    event ContractTraded(PositionId indexed positionId, Fill fill);
    event CollateralAdded(
        Symbol indexed symbol, address indexed trader, PositionId indexed positionId, uint256 amount, uint256 cost
    );
    event CollateralRemoved(
        Symbol indexed symbol, address indexed trader, PositionId indexed positionId, uint256 amount, uint256 cost
    );

    error InsufficientFCashFromLending(uint256 required, uint256 received);
    error OnlyFromVault(address expected, address actual);

    struct CreatePositionParams {
        Symbol symbol;
        address trader;
        uint256 quantity;
        uint256 limitCost;
        uint256 collateral;
        address payer;
        uint256 lendingLiquidity;
        uint24 uniswapFee;
    }

    function createPosition(CreatePositionParams calldata params) external returns (PositionId positionId) {
        if (params.quantity == 0) {
            revert InvalidQuantity(int256(params.quantity));
        }

        positionId = ConfigStorageLib.getPositionNFT().mint(params.trader);
        positionId.validatePayer(params.payer, params.trader);

        StorageLib.getPositionInstrument()[positionId] = params.symbol;
        (Instrument memory instrument, NotionalInstrument memory notionalInstrument) =
            _createPosition(params.symbol, positionId, params.uniswapFee);

        _open(
            params.symbol,
            positionId,
            params.trader,
            instrument,
            notionalInstrument,
            params.quantity.roundFloorNotionalPrecision(notionalInstrument.basePrecision),
            params.limitCost,
            params.collateral.toInt256(),
            params.payer,
            params.lendingLiquidity
        );
    }

    function _createPosition(Symbol symbol, PositionId positionId, uint24 uniswapFee)
        private
        returns (Instrument memory instrument, NotionalInstrument memory notionalInstrument)
    {
        (instrument, notionalInstrument,) = symbol.loadInstrument();

        if (instrument.maturity < block.timestamp) {
            revert InstrumentExpired(symbol, instrument.maturity, block.timestamp);
        }

        // no need to store the address since we can calculate it via ProxyLib.computeProxyAddress()
        ContangoVaultProxyDeployer(address(this)).deployVaultProxy(positionId, instrument);
        instrument.uniswapFeeTransient = uniswapFee;
    }

    function modifyPosition(
        PositionId positionId,
        int256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity,
        uint24 uniswapFee
    ) external {
        if (quantity == 0) {
            revert InvalidQuantity(quantity);
        }

        (uint256 openQuantity, address trader, Symbol symbol, Instrument memory instrument) =
            positionId.loadActivePosition(uniswapFee);
        if (collateral > 0) {
            positionId.validatePayer(payerOrReceiver, trader);
        }

        if (quantity < 0 && uint256(-quantity) > openQuantity) {
            revert InvalidPositionDecrease(positionId, quantity, openQuantity);
        }

        _modifyPosition(
            symbol,
            positionId,
            trader,
            instrument,
            quantity,
            openQuantity,
            limitCost,
            collateral,
            payerOrReceiver,
            lendingLiquidity
        );
    }

    function _modifyPosition(
        Symbol symbol,
        PositionId positionId,
        address trader,
        Instrument memory instrument,
        int256 quantity,
        uint256 openQuantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) private {
        NotionalInstrument memory notionalInstrument = NotionalStorageLib.getInstrument(positionId);
        uint256 uQuantity = quantity.abs().roundFloorNotionalPrecision(notionalInstrument.basePrecision);
        if (quantity > 0) {
            _open(
                symbol,
                positionId,
                trader,
                instrument,
                notionalInstrument,
                uQuantity,
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
                notionalInstrument,
                uQuantity,
                limitCost,
                collateral,
                payerOrReceiver,
                lendingLiquidity
            );
        }

        if (quantity < 0 && uint256(-quantity) == openQuantity) {
            positionId.deletePosition();
        }
    }

    function _open(
        Symbol symbol,
        PositionId positionId,
        address trader,
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument,
        uint256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) private {
        if (instrument.closingOnly) {
            revert InstrumentClosingOnly(symbol);
        }

        // Use a flash swap to buy enough base to hedge the position, pay directly to the pool where we'll lend it
        _flashBuyHedge(
            instrument,
            notionalInstrument,
            UniswapV3Handler.CallbackInfo({
                symbol: symbol,
                positionId: positionId,
                limitCost: limitCost,
                trader: trader,
                payerOrReceiver: payerOrReceiver,
                open: true,
                lendingLiquidity: lendingLiquidity
            }),
            quantity,
            collateral,
            address(this)
        );
    }

    function completeOpen(UniswapV3Handler.Callback memory callback) private {
        (Instrument memory instrument, NotionalInstrument memory notionalInstrument, ContangoVault vault) =
            callback.info.symbol.loadInstrument();

        // needs to borrow at least to cover uniswap costs
        uint256 amountToBorrow = callback.fill.hedgeCost;
        uint256 collateralPosted;
        if (callback.fill.collateral > 0) {
            collateralPosted = callback.fill.collateral.toUint256();
            // fully covered by the collateral posted
            amountToBorrow = (collateralPosted < amountToBorrow) ? amountToBorrow - collateralPosted : 0;
        } else if (callback.fill.collateral < 0) {
            // uniswap cost + withdrawn collateral
            amountToBorrow += callback.fill.collateral.abs();
        }

        // 3. enter vault by borrowing the quote owed to uniswap minus collateral and pass base amount as param
        // -> continues inside vault
        uint256 debt = _openEnterVault(callback, instrument, notionalInstrument, vault, amountToBorrow);

        uint256 remainingUniswapDebt = callback.fill.hedgeCost;
        if (callback.fill.collateral > 0) {
            // Trader can contribute up to the spot cost
            uint256 collateralUsed = Math.min(collateralPosted, callback.fill.hedgeCost);
            callback.fill.cost = debt + collateralUsed;
            callback.fill.collateral = collateralUsed.toInt256();
            remainingUniswapDebt -= collateralUsed;

            instrument.quote.transferOut(callback.info.payerOrReceiver, msg.sender, collateralUsed);
        }

        if (callback.fill.collateral < 0) {
            callback.fill.cost = callback.fill.hedgeCost + (debt - amountToBorrow);
        } else {
            callback.fill.cost = debt + callback.fill.collateral.toUint256();
        }

        SlippageLib.requireCostBelowTolerance(callback.fill.cost, callback.info.limitCost);

        // 6. repay uniswap
        if (remainingUniswapDebt > 0) {
            instrument.quote.transferOut(address(this), msg.sender, remainingUniswapDebt);
        }

        ExecutionProcessorLib.increasePosition({
            symbol: callback.info.symbol,
            positionId: callback.info.positionId,
            trader: callback.info.trader,
            size: callback.fill.size,
            cost: callback.fill.cost,
            collateralDelta: callback.fill.collateral,
            quoteToken: callback.instrument.quote,
            to: callback.info.payerOrReceiver,
            minCost: 0 // TODO alfredo - get from vault config
        });

        emit ContractTraded(callback.info.positionId, callback.fill);
    }

    function _openEnterVault(
        UniswapV3Handler.Callback memory callback,
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument,
        ContangoVault vault,
        uint256 amountToBorrow
    ) private returns (uint256 debt) {
        uint256 fCashToBorrow = amountToBorrow > 0
            ? NotionalStorageLib.NOTIONAL.quoteBorrowOpenCost(amountToBorrow, instrument, notionalInstrument)
            : 0;

        _openEnterVaultCall(
            OpenEnterVaultParams({
                positionId: callback.info.positionId,
                vault: vault,
                maturity: instrument.maturity,
                fCashToBorrow: fCashToBorrow,
                amountToBorrow: amountToBorrow,
                fCashLend: callback.fill.size.toNotionalPrecision(notionalInstrument.basePrecision, true),
                lendAmount: callback.fill.hedgeSize
            })
        );

        debt = fCashToBorrow.fromNotionalPrecision(notionalInstrument.quotePrecision, true);
    }

    function _openEnterVaultCall(OpenEnterVaultParams memory params) private {
        address proxy = params.positionId.computeProxyAddress(address(this), ConfigStorageLib.getProxyHash());
        // -> continues inside vault
        uint256 lentFCashAmount = NotionalProxy(proxy).enterVault({
            account: proxy,
            vault: address(params.vault),
            depositAmountExternal: 0,
            maturity: params.maturity,
            fCash: params.fCashToBorrow,
            maxBorrowRate: 0,
            vaultData: abi.encode(
                ContangoVault.EnterParams({
                    positionId: params.positionId,
                    payer: address(this),
                    // TODO alfredo - check gas savings by having two extra params and save one transfer (transfer to uni and trader from inside the vault)
                    receiver: address(this),
                    borrowAmount: params.amountToBorrow,
                    lendAmount: params.lendAmount,
                    fCashLendAmount: params.fCashLend
                })
                )
        });

        if (lentFCashAmount < params.fCashLend) {
            revert InsufficientFCashFromLending(params.fCashLend, lentFCashAmount);
        }
    }

    function _close(
        Symbol symbol,
        PositionId positionId,
        address trader,
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument,
        uint256 quantity,
        uint256 limitCost,
        int256 collateral,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) private {
        // Execute a flash swap to undo the hedge
        _flashSellHedge(
            instrument,
            notionalInstrument,
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
            address(this)
        );
    }

    function completeClose(UniswapV3Handler.Callback memory callback) private {
        (Instrument memory instrument, NotionalInstrument memory notionalInstrument, ContangoVault vault) =
            callback.info.symbol.loadInstrument();
        (uint256 openQuantity,) = StorageLib.getPositionNotionals()[callback.info.positionId].decodeU128();

        bool fullyClosing = openQuantity - callback.fill.size == 0;
        {
            uint256 balanceBefore = instrument.quote.balanceOf(address(this));

            // 3. Exit vault
            uint256 debtRepaid = _closeExitVault(callback, instrument, notionalInstrument, vault, fullyClosing)
                .fromNotionalPrecision(notionalInstrument.quotePrecision, false);

            uint256 repaymentCost = balanceBefore - instrument.quote.balanceOf(address(this));
            callback.fill.cost = callback.fill.hedgeCost + (debtRepaid - repaymentCost);
        }

        // TODO alfredo - check second clause and why it is needed
        // discount posted collateral from fill cost if applicable
        if (callback.fill.collateral > 0 && uint256(callback.fill.collateral) < callback.fill.cost) {
            callback.fill.cost -= uint256(callback.fill.collateral);
        }

        // 7. Pay swap with remaining base and transfer quote (inside ExecutionProcessorLib)
        instrument.base.transferOut(address(this), msg.sender, callback.fill.hedgeSize);

        SlippageLib.requireCostAboveTolerance(callback.fill.cost, callback.info.limitCost);

        emit ContractTraded(callback.info.positionId, callback.fill);

        if (fullyClosing) {
            ExecutionProcessorLib.closePosition({
                symbol: callback.info.symbol,
                positionId: callback.info.positionId,
                trader: callback.info.trader,
                cost: callback.fill.cost,
                quoteToken: callback.instrument.quote,
                to: callback.info.payerOrReceiver
            });
        } else {
            ExecutionProcessorLib.decreasePosition({
                symbol: callback.info.symbol,
                positionId: callback.info.positionId,
                trader: callback.info.trader,
                size: callback.fill.size,
                cost: callback.fill.cost,
                collateralDelta: callback.fill.collateral,
                quoteToken: callback.instrument.quote,
                to: callback.info.payerOrReceiver,
                minCost: 0 // TODO alfredo - get from vault config
            });
        }
    }

    function _closeExitVault(
        UniswapV3Handler.Callback memory callback,
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument,
        ContangoVault vault,
        bool fullyClosing
    ) private returns (uint256 fCashBorrowedToBurn) {
        address payable proxy =
            callback.info.positionId.computeProxyAddress(address(this), ConfigStorageLib.getProxyHash());
        VaultAccount memory vaultAccount = NotionalStorageLib.NOTIONAL.getVaultAccount(proxy, address(vault));

        // Can't withdraw more than what we got from UNI
        if (callback.fill.collateral < 0) {
            callback.fill.collateral = SignedMath.max(callback.fill.collateral, -callback.fill.hedgeCost.toInt256());
        }
        int256 quoteUsedToRepayDebt = callback.fill.hedgeCost.toInt256() + callback.fill.collateral;

        if (fullyClosing) {
            fCashBorrowedToBurn = vaultAccount.fCash.abs();
        } else {
            if (quoteUsedToRepayDebt > 0) {
                // If the user is depositing, take the necessary tokens
                if (callback.fill.collateral > 0) {
                    instrument.quote.transferOut(
                        callback.info.payerOrReceiver, address(this), uint256(callback.fill.collateral)
                    );
                }

                fCashBorrowedToBurn = NotionalStorageLib.NOTIONAL.quoteBorrowClose(
                    uint256(quoteUsedToRepayDebt), instrument, notionalInstrument
                );
            }
        }

        // track balances as Notional will send back any excess
        uint256 proxyBalanceBefore = notionalInstrument.isQuoteWeth ? proxy.balance : instrument.quote.balanceOf(proxy);

        // unwrap ETH ahead if applicable
        if (notionalInstrument.isQuoteWeth && quoteUsedToRepayDebt > 0) {
            WETH(payable(address(instrument.quote))).withdraw(uint256(quoteUsedToRepayDebt));
        }

        // skips a precision conversion and avoid possible dust issues when fully closing a position
        uint256 fCashLentToRedeem = fullyClosing
            ? vaultAccount.vaultShares
            : callback.fill.size.toNotionalPrecision(notionalInstrument.basePrecision, true);

        _closeExitVaultCall(
            CloseExitVaultParams({
                proxy: proxy,
                vault: vault,
                positionId: callback.info.positionId,
                fCashLentToRedeem: fCashLentToRedeem,
                fCashBorrowedToBurn: fCashBorrowedToBurn,
                repaymentAmount: quoteUsedToRepayDebt > 0 ? uint256(quoteUsedToRepayDebt) : 0,
                withdrawAmount: callback.fill.hedgeSize,
                isQuoteWeth: notionalInstrument.isQuoteWeth
            })
        );

        // TODO alfredo - evaluate if we want to leave the dust in the proxy itself
        _collectProxyQuoteBalance(proxy, proxyBalanceBefore, instrument.quote, notionalInstrument.isQuoteWeth);
    }

    function _closeExitVaultCall(CloseExitVaultParams memory params) private {
        // --> continues inside vault
        uint256 sendValue = params.isQuoteWeth ? params.repaymentAmount : 0;
        NotionalProxy(params.proxy).exitVault{value: sendValue}({
            account: params.proxy,
            vault: address(params.vault),
            receiver: address(params.vault), // TODO alfredo - review where we want this dust sent
            vaultSharesToRedeem: params.fCashLentToRedeem,
            fCashToLend: params.fCashBorrowedToBurn,
            minLendRate: 0,
            exitVaultData: abi.encode(
                ContangoVault.ExitParams({
                    positionId: params.positionId,
                    // TODO alfredo - check gas savings by having two extra params and save one transfer (transfer from contango (swap) and trader from inside the vault)
                    payer: address(this),
                    receiver: address(this),
                    withdrawAmount: params.withdrawAmount
                })
                )
        });
    }

    function _flashBuyHedge(
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument,
        UniswapV3Handler.CallbackInfo memory callbackInfo,
        uint256 quantity,
        int256 collateral,
        address to
    ) private {
        UniswapV3Handler.Callback memory callback;

        callback.fill.size = quantity;
        callback.fill.collateral = collateral;

        // 1. quote base fCash
        uint256 fCashQuantity = callback.fill.size.toNotionalPrecision(notionalInstrument.basePrecision, true);
        callback.fill.hedgeSize =
            NotionalStorageLib.NOTIONAL.quoteLendOpenCost(fCashQuantity, instrument, notionalInstrument);

        callback.info = callbackInfo;

        // 2. flash swap to get quoted base
        // -> continues inside flashswap callback
        UniswapV3Handler.flashSwap(callback, instrument, false, to);
    }

    /// @dev calculates the amount of base ccy to sell based on the traded quantity and executes a flash swap
    function _flashSellHedge(
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument,
        UniswapV3Handler.CallbackInfo memory callbackInfo,
        uint256 quantity,
        int256 collateral,
        address to
    ) private {
        UniswapV3Handler.Callback memory callback;

        callback.fill.size = quantity;
        callback.fill.collateral = collateral;

        // 1. Quote how much base for base fCash
        uint256 fCashQuantity = callback.fill.size.toNotionalPrecision(notionalInstrument.basePrecision, true);
        callback.fill.hedgeSize =
            NotionalStorageLib.NOTIONAL.quoteLendClose(fCashQuantity, instrument, notionalInstrument);

        callback.info = callbackInfo;

        // 2. Flash swap to get quote
        // -> continues inside flashswap callback
        UniswapV3Handler.flashSwap(callback, instrument, true, to);
    }

    // ============== Uniswap functions ==============

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        UniswapV3Handler.uniswapV3SwapCallback(amount0Delta, amount1Delta, data, _onUniswapCallback);
    }

    function _onUniswapCallback(UniswapV3Handler.Callback memory callback) internal {
        if (callback.info.open) completeOpen(callback);
        else completeClose(callback);
    }

    // ============== Collateral management ==============

    function modifyCollateral(
        PositionId positionId,
        int256 collateral,
        uint256 slippageTolerance,
        address payerOrReceiver,
        uint256 lendingLiquidity
    ) external {
        (, address trader, Symbol symbol, Instrument memory instrument) = positionId.loadActivePosition(0);

        uint256 uCollateral = collateral.abs();
        if (collateral > 0) {
            positionId.validatePayer(payerOrReceiver, trader);
            _addCollateral(
                symbol,
                positionId,
                trader,
                instrument,
                uCollateral,
                slippageTolerance,
                payerOrReceiver,
                lendingLiquidity
            );
        } else if (collateral < 0) {
            _removeCollateral(symbol, positionId, trader, instrument, uCollateral, slippageTolerance, payerOrReceiver);
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
        NotionalInstrument memory notionalInstrument = NotionalStorageLib.getInstruments()[symbol];
        ContangoVault vault = NotionalStorageLib.getVaults()[symbol];

        address payable proxy = positionId.computeProxyAddress(address(this), ConfigStorageLib.getProxyHash());
        uint256 proxyBalanceBefore = notionalInstrument.isQuoteWeth ? proxy.balance : instrument.quote.balanceOf(proxy);

        _handleAddCollateralFunds(instrument, notionalInstrument, payer, proxy, collateral);

        if (lendingLiquidity == 0) {
            revert NotImplemented("_addCollateral() - force: true");
        }

        // Quote how much debt can be burned with collateral provided
        uint256 fCashBorrowedToBurn =
            NotionalStorageLib.NOTIONAL.quoteBorrowClose(collateral, instrument, notionalInstrument);
        uint256 debtBurnt = fCashBorrowedToBurn.fromNotionalPrecision(notionalInstrument.quotePrecision, false);
        // Burn debt
        _addCollateralExitVault(
            AddCollateralExitVaultParams({
                proxy: proxy,
                vault: vault,
                positionId: positionId,
                fCashBorrowedToBurn: fCashBorrowedToBurn,
                collateral: collateral,
                isQuoteWeth: notionalInstrument.isQuoteWeth
            })
        );

        SlippageLib.requireCostAboveTolerance(debtBurnt, slippageTolerance);

        _processUpdateCollateral(symbol, positionId, trader, collateral, debtBurnt);

        _collectProxyQuoteBalance(proxy, proxyBalanceBefore, instrument.quote, notionalInstrument.isQuoteWeth);
    }

    function _handleAddCollateralFunds(
        Instrument memory instrument,
        NotionalInstrument memory notionalInstrument,
        address payer,
        address payable proxy,
        uint256 collateral
    ) private {
        if (notionalInstrument.isQuoteWeth) {
            WETH(payable(address(instrument.quote))).withdraw(collateral);
        } else {
            // TODO alfredo - see if we can tell Notional where to pull the funds from to avoid these transfers and approvals
            // Transfer the new collateral from the payer to the proxy and allow Notional to pull funds
            instrument.quote.transferOut(payer, proxy, collateral);
            PermissionedProxy(proxy).approve({
                token: instrument.quote,
                spender: address(NotionalStorageLib.NOTIONAL),
                amount: collateral
            });
        }
    }

    function _addCollateralExitVault(AddCollateralExitVaultParams memory params) private {
        // TODO alfredo - some operations can be done without wrap/unwrap and save some gas
        uint256 sendValue = params.isQuoteWeth ? params.collateral : 0;
        NotionalProxy(params.proxy).exitVault{value: sendValue}({
            account: params.proxy,
            vault: address(params.vault),
            receiver: address(params.vault), // TODO alfredo - review where we want this dust sent
            vaultSharesToRedeem: 0,
            fCashToLend: params.fCashBorrowedToBurn,
            minLendRate: 0,
            exitVaultData: abi.encode(
                ContangoVault.ExitParams({
                    positionId: params.positionId,
                    payer: address(0),
                    receiver: address(this),
                    withdrawAmount: 0
                })
                )
        });
    }

    function _processUpdateCollateral(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 collateral,
        uint256 debtBurnt
    ) private {
        // The interest pnl is reflected on the position cost
        int256 cost = -(debtBurnt - collateral).toInt256();

        ExecutionProcessorLib.updateCollateral({
            symbol: symbol,
            positionId: positionId,
            trader: trader,
            cost: cost,
            amount: int256(collateral)
        });

        emit CollateralAdded(symbol, trader, positionId, collateral, debtBurnt);
    }

    function _removeCollateral(
        Symbol symbol,
        PositionId positionId,
        address trader,
        Instrument memory instrument,
        uint256 collateral,
        uint256 slippageTolerance,
        address receiver
    ) private {
        NotionalInstrument memory notionalInstrument = NotionalStorageLib.getInstruments()[symbol];
        ContangoVault vault = NotionalStorageLib.getVaults()[symbol];

        // Borrow whatever the trader wants to withdraw
        uint256 debt = _removeCollateralEnterVault(
            RemoveCollateralEnterVaultParams({
                positionId: positionId,
                vault: vault,
                maturity: instrument.maturity,
                fCashToBorrow: NotionalStorageLib.NOTIONAL.quoteBorrowOpenCost(collateral, instrument, notionalInstrument),
                collateral: collateral,
                receiver: receiver,
                quotePrecision: notionalInstrument.quotePrecision
            })
        );

        SlippageLib.requireCostBelowTolerance(debt, slippageTolerance);

        // The interest pnl is reflected on the position cost
        int256 cost = int256(debt - collateral);

        // cast to int is safe as it was previously int256
        ExecutionProcessorLib.updateCollateral({
            symbol: symbol,
            positionId: positionId,
            trader: trader,
            cost: cost,
            amount: -int256(collateral)
        });

        emit CollateralRemoved(symbol, trader, positionId, collateral, debt);
    }

    function _removeCollateralEnterVault(RemoveCollateralEnterVaultParams memory params)
        private
        returns (uint256 debt)
    {
        debt = params.fCashToBorrow.fromNotionalPrecision(params.quotePrecision, true);

        address proxy = params.positionId.computeProxyAddress(address(this), ConfigStorageLib.getProxyHash());
        NotionalProxy(proxy).enterVault({
            account: proxy,
            vault: address(params.vault),
            depositAmountExternal: 0,
            maturity: params.maturity,
            fCash: params.fCashToBorrow,
            maxBorrowRate: 0,
            vaultData: abi.encode(
                ContangoVault.EnterParams({
                    positionId: params.positionId,
                    payer: address(0),
                    receiver: params.receiver,
                    borrowAmount: params.collateral,
                    lendAmount: 0,
                    fCashLendAmount: 0
                })
                )
        });
    }

    // ============== Physical delivery ==============

    function deliver(PositionId positionId, address payer, address to) external {
        address trader = positionId.positionOwner();
        positionId.validatePayer(payer, trader);

        (uint256 openQuantity, Symbol symbol, Instrument memory instrument) = positionId.validateExpiredPosition();

        _deliver(symbol, positionId, openQuantity, trader, instrument, payer, to);

        positionId.deletePosition();
    }

    function _deliver(
        Symbol symbol,
        PositionId positionId,
        uint256 openQuantity,
        address trader,
        Instrument memory instrument,
        address payer,
        address to
    ) private {
        NotionalInstrument memory notionalInstrument = NotionalStorageLib.getInstruments()[symbol];
        ContangoVault vault = NotionalStorageLib.getVaults()[symbol];

        address payable proxy = positionId.computeProxyAddress(address(this), ConfigStorageLib.getProxyHash());
        uint256 proxyBalanceBefore = notionalInstrument.isQuoteWeth ? proxy.balance : instrument.quote.balanceOf(proxy);

        VaultAccount memory vaultAccount = NotionalStorageLib.NOTIONAL.getVaultAccount(proxy, address(vault));

        if (vaultAccount.fCash == 0) {
            // TODO alfredo - revisit on liquidation
            revert NotImplemented("_deliver() - no debt");
        }

        // debt/lend value remains the same either at maturity or any time after + buffer for rounding issues
        uint256 requiredQuote = uint256(-vaultAccount.fCash).fromNotionalPrecision(
            notionalInstrument.quotePrecision, true
        ).buffer(notionalInstrument.quotePrecision);

        // transfer required quote from payer and settle vault
        instrument.quote.transferOut(payer, address(this), requiredQuote);
        if (notionalInstrument.isQuoteWeth) {
            WETH(payable(address(instrument.quote))).withdraw(uint256(requiredQuote));
        }

        // by only doing the settling, the vault accounts will be left without its accounting being updated,
        // this is not a problem since we'll transfer the corresponding debt repayment to vault anyway and
        // Notional should clear all vault accounts once all vault shares are redeemed and the full vault is settled.
        _settleVaultAccount(
            SettleVaultAccountParams({
                vault: vault,
                proxy: proxy,
                maturity: instrument.maturity,
                repaymentAmount: requiredQuote,
                withdrawAmount: openQuantity,
                to: to,
                isQuoteWeth: notionalInstrument.isQuoteWeth
            })
        );

        _processDeliverPosition({
            symbol: symbol,
            positionId: positionId,
            instrument: instrument,
            trader: trader,
            deliverableQuantity: openQuantity,
            deliveryCost: requiredQuote,
            payer: payer,
            to: to
        });

        _collectProxyQuoteBalance(proxy, proxyBalanceBefore, instrument.quote, notionalInstrument.isQuoteWeth);
    }

    function _settleVaultAccount(SettleVaultAccountParams memory params) private {
        uint256 sendValue = params.isQuoteWeth ? params.repaymentAmount : 0;
        params.vault.settleAccount{value: sendValue}({
            account: params.proxy,
            maturity: params.maturity,
            data: abi.encode(
                ContangoVault.SettleParams({
                    payer: address(this),
                    receiver: params.to,
                    repaymentAmount: params.repaymentAmount,
                    withdrawAmount: params.withdrawAmount
                })
                )
        });
    }

    function _processDeliverPosition(
        Symbol symbol,
        PositionId positionId,
        Instrument memory instrument,
        address trader,
        uint256 deliverableQuantity,
        uint256 deliveryCost,
        address payer,
        address to
    ) private {
        ExecutionProcessorLib.deliverPosition({
            symbol: symbol,
            positionId: positionId,
            trader: trader,
            deliverableQuantity: deliverableQuantity,
            deliveryCost: deliveryCost,
            payer: payer,
            quoteToken: instrument.quote,
            to: to
        });
    }

    // ============== Liquidation ==============

    function onVaultAccountDeleverage(PositionId positionId, uint256 size, uint256 cost) external {
        (uint256 openQuantity, Symbol symbol,) = positionId.validateActivePosition(0);
        address vault = address(NotionalStorageLib.getVaults()[symbol]);
        if (msg.sender != vault) {
            revert OnlyFromVault(vault, msg.sender);
        }

        // TODO alfredo - this is not pretty, confirm there's no other more elegant solution
        // go around off by one error on notional side, ensuring full liquidation is processed properly
        uint256 scaledOne =
            uint256(1).fromNotionalPrecision(NotionalStorageLib.getInstrument(positionId).basePrecision, true);
        if (size == openQuantity - scaledOne) {
            size = openQuantity;
        }

        ExecutionProcessorLib.liquidatePosition({
            symbol: symbol,
            positionId: positionId,
            trader: ConfigStorageLib.getPositionNFT().positionOwner(positionId),
            size: size,
            cost: cost
        });
    }

    function _collectProxyQuoteBalance(address payable proxy, uint256 floor, ERC20 quote, bool isQuoteWeth) private {
        // dust may accumulate due to:
        // - Notional debt repayment quoting mismatching with execution
        // - cost rounding in our protocol's favours
        uint256 currentBalance = isQuoteWeth ? proxy.balance : quote.balanceOf(proxy);
        uint256 collectableBalance = currentBalance - floor;
        if (collectableBalance > 0) {
            if (isQuoteWeth) {
                PermissionedProxy(proxy).collectBalance(collectableBalance);
                WETH(payable(address(quote))).deposit{value: collectableBalance}();
            } else {
                quote.transferOut(proxy, address(this), collectableBalance);
            }
        }
    }
}