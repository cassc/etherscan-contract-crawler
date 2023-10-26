//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../moneymarkets/interfaces/IFlashBorrowProvider.sol";

import "../interfaces/IContango.sol";

import "../utils/SpotExecutor.sol";

import "../libraries/ERC20Lib.sol";
import "../libraries/Errors.sol";
import "../libraries/MathLib.sol";
import "../libraries/Roles.sol";
import "../libraries/Validations.sol";

import "./PositionNFT.sol";

contract Contango is IContango, AccessControlUpgradeable, PausableUpgradeable, UUPSUpgradeable {

    using Math for *;
    using SafeCast for *;
    using SignedMath for *;
    using { validateCreatePositionPermissions, validateModifyPositionPermissions } for PositionNFT;
    using { cashflowToken, encodeFlashLoanCallback } for FlashLoanCallback;
    using { decodeFlashLoanCallback } for bytes;

    struct FlashLoanCallback {
        ExecutionParams ep;
        uint256 quantity;
        int256 cashflow;
        address owner;
        Currency cashflowCcy;
        InstrumentStorage instrument;
        PositionId positionId;
        IMoneyMarket moneyMarket;
        uint256 limitPrice;
        bool fullyClosing;
    }

    struct InstrumentStorage {
        Symbol symbol;
        bool closingOnly;
        IERC20 base;
        uint64 baseUnit;
        IERC20 quote;
        uint64 quoteUnit;
    }

    PositionNFT public immutable positionNFT;
    IVault public immutable vault;
    IUnderlyingPositionFactory public immutable positionFactory;
    IFeeManager public immutable feeManager;
    SpotExecutor public immutable spotExecutor;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * mixins without shifting down storage in this contract.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     *
     * After adding some OZ mixins, we consumed 301 slots from the original 50k gap.
     */
    uint256[50_000 - 301] private __gap;

    uint256[4] private __dead; // TODO kill if we re-deploy
    bytes32 private callbackHash;
    bytes32 private tradeHash;
    mapping(PositionId positionId => address owner) private lastOwner;
    mapping(Symbol symbol => InstrumentStorage instrument) private instruments;

    constructor(PositionNFT nft, IVault v, IUnderlyingPositionFactory pf, IFeeManager fm, SpotExecutor spot) {
        positionNFT = nft;
        vault = v;
        positionFactory = pf;
        feeManager = fm;
        spotExecutor = spot;
    }

    function initialize(Timelock timelock) public initializer {
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __UUPSUpgradeable_init_unchained();
        _grantRole(DEFAULT_ADMIN_ROLE, Timelock.unwrap(timelock));
    }

    // ============================= IContango =========================

    function _getOrCreatePosition(PositionId positionId, address owner)
        internal
        returns (PositionId positionId_, InstrumentStorage memory instrument_, IMoneyMarket moneyMarket)
    {
        (Symbol symbol,,, uint256 id) = positionId.decode();
        instrument_ = instruments[symbol];

        if (id == 0) {
            if (address(instrument_.base) == address(0)) revert InvalidInstrument(symbol);
            positionNFT.validateCreatePositionPermissions(owner);
            positionId_ = positionNFT.mint(positionId, owner);
            moneyMarket = positionFactory.createUnderlyingPosition(positionId_);
            SafeERC20.forceApprove(instrument_.base, address(moneyMarket), type(uint256).max);
            SafeERC20.forceApprove(instrument_.quote, address(moneyMarket), type(uint256).max);
            moneyMarket.initialise(positionId_, instrument_.base, instrument_.quote);
        } else {
            positionNFT.validateModifyPositionPermissions(positionId);
            positionId_ = positionId;
            moneyMarket = _moneyMarket(positionId);
        }
    }

    function trade(TradeParams calldata tradeParams, ExecutionParams calldata execParams)
        public
        payable
        override
        returns (PositionId, Trade memory)
    {
        return tradeOnBehalfOf(tradeParams, execParams, msg.sender);
    }

    function tradeOnBehalfOf(TradeParams calldata tradeParams, ExecutionParams calldata execParams, address onBehalfOf)
        public
        payable
        override
        returns (PositionId positionId, Trade memory trade_)
    {
        _requireNotPaused();
        address owner;
        positionId = tradeParams.positionId;
        if (tradeParams.quantity > 0) {
            owner = onBehalfOf;
            (positionId, trade_) = _open(tradeParams, execParams, onBehalfOf);
        } else if (tradeParams.quantity < 0) {
            (trade_, owner) = _close(tradeParams, execParams);
        } else {
            (trade_, owner) = _modify(tradeParams, execParams);
        }

        _emitPositionUpserted(positionId, trade_, owner);
    }

    function _open(TradeParams calldata tradeParams, ExecutionParams calldata execParams, address onBehalfOf)
        private
        returns (PositionId positionId_, Trade memory trade_)
    {
        InstrumentStorage memory _instrument;
        IMoneyMarket moneyMarket;
        (positionId_, _instrument, moneyMarket) = _getOrCreatePosition({ positionId: tradeParams.positionId, owner: onBehalfOf });
        _validateCashflowCcy({ _instrument: _instrument, cashflowCcy: tradeParams.cashflowCcy, fullyClosing: false });
        if (_instrument.closingOnly || positionId_.isExpired()) revert ClosingOnly();

        FlashLoanCallback memory cb = FlashLoanCallback({
            ep: execParams,
            quantity: tradeParams.quantity.toUint256(),
            cashflow: tradeParams.cashflow,
            cashflowCcy: tradeParams.cashflowCcy,
            instrument: _instrument,
            positionId: positionId_,
            moneyMarket: moneyMarket,
            limitPrice: tradeParams.limitPrice,
            owner: onBehalfOf,
            fullyClosing: false
        });

        if (_bypassFlashLoanOnOpen(cb)) {
            trade_ = _completeOpen({ asset: cb.cashflowToken(), amountOwed: 0, cb: cb, repayTo: address(0) });
        } else {
            // cover swap taking into account possible quote cashflow changes
            uint256 flashLoanAmount = tradeParams.cashflowCcy == Currency.Quote
                ? (execParams.swapAmount.toInt256() - tradeParams.cashflow).toUint256()
                : execParams.swapAmount;

            bytes memory result;
            if (moneyMarket.supportsInterface(type(IFlashBorrowProvider).interfaceId)) {
                result = IFlashBorrowProvider(address(moneyMarket)).flashBorrow({
                    asset: _instrument.quote,
                    amount: flashLoanAmount,
                    params: cb.encodeFlashLoanCallback(),
                    callback: this.completeOpenFromFlashBorrow
                });
            } else {
                result = _flash({
                    provider: execParams.flashLoanProvider,
                    loanReceiver: address(this),
                    asset: address(_instrument.quote),
                    amount: flashLoanAmount,
                    data: cb.encodeFlashLoanCallback(),
                    callback: this.completeOpenFromFlashLoan
                });
            }
            trade_ = validateHashAndDecodeTrade(result);
        }

        _openSlippageCheck(tradeParams, trade_, _instrument);
    }

    function _bypassFlashLoanOnOpen(FlashLoanCallback memory cb) private pure returns (bool) {
        // enoughQuoteForOpenSwap || enoughBaseForOpenSwap
        return cb.cashflowCcy == Currency.Quote && MathLib.absIfPositive(cb.cashflow) >= cb.ep.swapAmount
            || cb.cashflowCcy == Currency.Base && MathLib.absIfPositive(cb.cashflow) >= cb.quantity;
    }

    function completeOpenFromFlashBorrow(IERC20 asset, uint256 amountOwed, bytes calldata params)
        external
        override
        returns (bytes memory result)
    {
        FlashLoanCallback memory cb = params.decodeFlashLoanCallback();
        if (address(_moneyMarket(cb.positionId)) != msg.sender) revert NotFlashBorrowProvider(msg.sender);
        return encodeTradeAndHash(_completeOpen(asset, amountOwed, cb, address(0)));
    }

    function completeOpenFromFlashLoan(
        address, /* initiator */
        address repayTo,
        address asset,
        uint256 amount,
        uint256 fee,
        bytes calldata params
    ) external override returns (bytes memory result) {
        return encodeTradeAndHash(_completeOpen(IERC20(asset), amount + fee, _flashLoanCallback(params), repayTo));
    }

    function _completeOpen(IERC20 asset, uint256 amountOwed, FlashLoanCallback memory cb, address repayTo)
        private
        returns (Trade memory trade_)
    {
        trade_.cashflowCcy = cb.cashflowCcy;
        trade_.cashflow = cb.cashflow;

        // if applicable, transfer any required cashflow in before executing swaps
        _handlePositiveCashflow(cb);

        trade_.swap = _executeSwap(cb.ep, cb.instrument, asset);

        // if applicable, transfer any required base out before increasing quantity
        if (cb.cashflowCcy == Currency.Base) _handleNegativeCashflow(cb);

        uint256 quantity = ERC20Lib.myBalance(cb.instrument.base);

        // if applicable, protect against swap overspending base
        _ensureEnoughBaseAfterSwap(trade_.swap, cb.cashflow, quantity);

        (trade_.fee, trade_.feeCcy) = _applyFee(cb, quantity);

        trade_.quantity = cb.moneyMarket.lend(cb.positionId, cb.instrument.base, quantity - trade_.fee).toInt256();

        uint256 repaid = ERC20Lib.myBalance(cb.instrument.quote);
        if (repaid > 0 && cb.cashflow > 0) {
            // actual repaid amount is ignored due to forward value possibility and trade cashflow is adjusted with remaining quote
            _repayFromMarket(cb.moneyMarket, cb.positionId, cb.instrument.quote, repaid);
        }

        uint256 borrowed = amountOwed;
        if (repayTo != address(0)) borrowed = _borrowFromMarket(cb.moneyMarket, cb.positionId, cb.instrument.quote, amountOwed, repayTo);

        // if applicable, transfer out required quote
        if (cb.cashflowCcy == Currency.Quote) _handleNegativeCashflow(cb);

        // adjust cashflow when it's quote, positive and not all of it was used
        int256 unusedQuoteCashflow = _handleRemainingQuote(cb.owner, cb.instrument, trade_);
        trade_.cashflow -= unusedQuoteCashflow;
        repaid -= unusedQuoteCashflow.toUint256();

        trade_.forwardPrice = _hasForwardPrice(cb) ? _forwardPriceOnOpen(cb, trade_, quantity, borrowed, repaid) : trade_.swap.price;
    }

    function _openSlippageCheck(TradeParams memory tradeParams, Trade memory _trade, InstrumentStorage memory _instrument) private pure {
        if (_trade.forwardPrice > tradeParams.limitPrice) {
            revert PriceAboveLimit({ limit: tradeParams.limitPrice, actual: _trade.forwardPrice });
        }

        if (_trade.swap.inputCcy == Currency.Quote) {
            uint256 expectedBaseOutput = (
                tradeParams.quantity - (tradeParams.cashflowCcy == Currency.Base ? tradeParams.cashflow : int256(0)) + _trade.fee.toInt256()
            ).toUint256(); // can never be negative, if it was it would mean no swap was needed

            uint256 maxQuoteInput = expectedBaseOutput.mulDiv(tradeParams.limitPrice, _instrument.baseUnit);
            uint256 uSwapInput = (-_trade.swap.input).toUint256();
            if (uSwapInput > maxQuoteInput) revert ExcessiveInputQuote({ limit: maxQuoteInput, actual: uSwapInput });
        }
    }

    function _close(TradeParams memory tradeParams, ExecutionParams calldata execParams)
        private
        returns (Trade memory trade_, address owner)
    {
        owner = positionNFT.validateModifyPositionPermissions(tradeParams.positionId);
        InstrumentStorage memory _instrument = instruments[tradeParams.positionId.getSymbol()];
        IMoneyMarket moneyMarket = _moneyMarket(tradeParams.positionId);

        uint256 collateralBalance = moneyMarket.collateralBalance(tradeParams.positionId, _instrument.base);
        uint256 quantity = Math.min(tradeParams.quantity.abs(), collateralBalance);

        FlashLoanCallback memory cb = FlashLoanCallback({
            ep: execParams,
            quantity: quantity,
            cashflow: tradeParams.cashflow,
            cashflowCcy: tradeParams.cashflowCcy,
            instrument: _instrument,
            positionId: tradeParams.positionId,
            moneyMarket: moneyMarket,
            limitPrice: tradeParams.limitPrice,
            owner: owner,
            fullyClosing: quantity == collateralBalance
        });

        if (cb.positionId.isExpired() && !cb.fullyClosing) revert OnlyFullClosureAllowedAfterExpiry();
        _validateCashflowCcy({ _instrument: _instrument, cashflowCcy: cb.cashflowCcy, fullyClosing: cb.fullyClosing });

        if (_bypassFlashLoanOnClose(cb)) {
            IERC20 asset;
            if (execParams.swapAmount > 0) {
                asset = _instrument.quote;
                _borrowFromMarket(cb.moneyMarket, cb.positionId, asset, execParams.swapAmount, address(this));
            }
            trade_ = _completeClose({ asset: asset, amountOwed: execParams.swapAmount, cb: cb, repayTo: address(0) });
        } else {
            trade_ = validateHashAndDecodeTrade(
                _flash({
                    provider: execParams.flashLoanProvider,
                    loanReceiver: address(this),
                    asset: address(_instrument.base),
                    amount: execParams.swapAmount,
                    data: cb.encodeFlashLoanCallback(),
                    callback: this.completeClose
                })
            );
        }

        _closeSlippageCheck(tradeParams, trade_, cb.quantity, cb.fullyClosing);

        if (cb.fullyClosing) {
            lastOwner[tradeParams.positionId] = owner;
            positionNFT.burn(tradeParams.positionId);
        }
    }

    function _emitPositionUpserted(PositionId positionId, Trade memory _trade, address owner) private {
        emit PositionUpserted({
            positionId: positionId,
            owner: owner,
            tradedBy: msg.sender,
            cashflowCcy: _trade.cashflowCcy,
            cashflow: _trade.cashflow,
            quantityDelta: _trade.quantity,
            price: _trade.swap.price,
            fee: _trade.fee,
            feeCcy: _trade.feeCcy
        });
    }

    function _bypassFlashLoanOnClose(FlashLoanCallback memory cb) private pure returns (bool) {
        return cb.cashflowCcy == Currency.Base && cb.quantity <= MathLib.absIfNegative(cb.cashflow);
    }

    function completeClose(address, /* initiator */ address repayTo, address asset, uint256 amount, uint256 fee, bytes calldata params)
        external
        override
        returns (bytes memory result)
    {
        return encodeTradeAndHash(_completeClose(IERC20(asset), amount + fee, _flashLoanCallback(params), repayTo));
    }

    function _completeClose(IERC20 asset, uint256 amountOwed, FlashLoanCallback memory cb, address repayTo)
        private
        returns (Trade memory trade_)
    {
        trade_.cashflowCcy = cb.cashflowCcy;
        trade_.cashflow = cb.cashflow;

        // if applicable, transfer any required cashflow in before executing swaps
        _handlePositiveCashflow(cb);

        if (asset == cb.instrument.base) trade_.swap = _executeSwap(cb.ep, cb.instrument, cb.instrument.base);

        uint256 quoteBalance = ERC20Lib.myBalance(cb.instrument.quote);
        uint256 repaid;
        if (!_bypassFlashLoanOnClose(cb)) {
            uint256 repaymentAmount = quoteBalance;
            // if applicable, discount quote cashflow to be transferred out from debt repayment
            if (!cb.fullyClosing && cb.cashflowCcy == Currency.Quote && cb.cashflow < 0) {
                repaymentAmount -= Math.min(cb.cashflow.abs(), quoteBalance);
            }

            if (repaymentAmount != 0) repaid = _repayFromMarket(cb.moneyMarket, cb.positionId, cb.instrument.quote, repaymentAmount);
        }

        if (cb.cashflowCcy == Currency.Quote && cb.cashflow < 0) {
            uint256 uCashflow = cb.cashflow.abs();
            if (quoteBalance < uCashflow) {
                _borrowFromMarket(cb.moneyMarket, cb.positionId, cb.instrument.quote, uCashflow - quoteBalance, address(this));
            }
        }

        uint256 withdrawn = cb.moneyMarket.withdraw(cb.positionId, cb.instrument.base, cb.quantity, address(this));

        if (asset == cb.instrument.quote) trade_.swap = _executeSwap(cb.ep, cb.instrument, cb.instrument.quote);

        if (repayTo != address(0)) ERC20Lib.transferOut(asset, address(this), repayTo, amountOwed);

        (trade_.fee, trade_.feeCcy) = _applyFee(cb, withdrawn);

        trade_.quantity = -cb.quantity.toInt256();
        if (cb.cashflow <= 0) {
            if (cb.cashflowCcy == Currency.Base) {
                // transfer remaining unused quote that could occur if swap was overshot to cover debt repayment
                _depositBalance(cb.instrument.quote, cb.owner);
            }
            trade_.cashflow = -_depositBalance(cb.cashflowToken(), cb.owner).toInt256();
        }

        // adjust cashflow when it's quote, positive and not all of it was used
        trade_.cashflow -= _handleRemainingQuote(cb.owner, cb.instrument, trade_);

        trade_.forwardPrice = _hasForwardPrice(cb) ? _forwardPriceOnClose(cb, trade_, repaid, withdrawn) : trade_.swap.price;
    }

    function _closeSlippageCheck(TradeParams memory tradeParams, Trade memory _trade, uint256 quantity, bool fullyClose) private pure {
        // price & forwardPrice will be 0 when we don't swap
        if (_trade.forwardPrice > 0 && _trade.forwardPrice < tradeParams.limitPrice) {
            revert PriceBelowLimit({ limit: tradeParams.limitPrice, actual: _trade.forwardPrice });
        }

        // Scenarios 19, 30: _guaranteedBaseCashflowRemoval
        if (
            !fullyClose && tradeParams.cashflowCcy == Currency.Base && tradeParams.cashflow < 0 && _trade.swap.inputCcy == Currency.Base
                && MathLib.absIfNegative(tradeParams.cashflow) <= quantity && tradeParams.cashflow < _trade.cashflow
        ) revert InsufficientBaseCashflow({ expected: tradeParams.cashflow, actual: _trade.cashflow });
    }

    function _modify(TradeParams calldata tradeParams, ExecutionParams calldata execParams)
        private
        returns (Trade memory trade_, address owner)
    {
        if (tradeParams.positionId.isExpired()) revert ClosingOnly();
        owner = positionNFT.validateModifyPositionPermissions(tradeParams.positionId);
        InstrumentStorage memory _instrument = instruments[tradeParams.positionId.getSymbol()];
        _validateCashflowCcy({ _instrument: _instrument, cashflowCcy: tradeParams.cashflowCcy, fullyClosing: false });
        IMoneyMarket moneyMarket = _moneyMarket(tradeParams.positionId);

        trade_.cashflowCcy = tradeParams.cashflowCcy;
        bool cashflowInBase = tradeParams.cashflowCcy == Currency.Base;
        IERC20 _cashflowToken = cashflowInBase ? _instrument.base : _instrument.quote;

        if (tradeParams.cashflow > 0) {
            _withdrawFromVault({ token: _cashflowToken, account: owner, amount: uint256(tradeParams.cashflow), to: address(this) });
            trade_.cashflow = tradeParams.cashflow;

            if (cashflowInBase) trade_.swap = _executeSwap(execParams, _instrument, _instrument.base);

            _repayFromMarket(moneyMarket, tradeParams.positionId, _instrument.quote, ERC20Lib.myBalance(_instrument.quote));

            // adjust cashflow when it's quote, positive and not all of it was used
            trade_.cashflow -= _handleRemainingQuote(owner, _instrument, trade_);
        } else {
            uint256 borrowAmount = cashflowInBase ? execParams.swapAmount : tradeParams.cashflow.abs();
            _borrowFromMarket(moneyMarket, tradeParams.positionId, _instrument.quote, borrowAmount, address(this));

            if (cashflowInBase) trade_.swap = _executeSwap(execParams, _instrument, _instrument.quote);
            trade_.cashflow = -_depositBalance(_cashflowToken, owner).toInt256();
        }

        if (trade_.swap.inputCcy == Currency.Base) {
            if (tradeParams.limitPrice > trade_.swap.price) {
                revert PriceBelowLimit({ limit: tradeParams.limitPrice, actual: trade_.swap.price });
            }
        } else {
            if (trade_.swap.price > tradeParams.limitPrice) {
                revert PriceAboveLimit({ limit: tradeParams.limitPrice, actual: trade_.swap.price });
            }
        }
    }

    function _executeSwap(ExecutionParams memory execParams, InstrumentStorage memory _instrument, IERC20 tokenToSell)
        internal
        returns (SwapInfo memory swap)
    {
        if (execParams.swapAmount != 0) {
            IERC20 tokenToBuy;
            (swap.inputCcy, tokenToBuy) =
                tokenToSell == _instrument.base ? (Currency.Base, _instrument.quote) : (Currency.Quote, _instrument.base);

            ERC20Lib.transferOut(tokenToSell, address(this), address(spotExecutor), execParams.swapAmount);
            (swap.input, swap.output, swap.price) =
                spotExecutor.executeSwap(tokenToSell, tokenToBuy, swap.inputCcy, _instrument.baseUnit, execParams);
        }
    }

    function _ensureEnoughBaseAfterSwap(SwapInfo memory swap, int256 cashflow, uint256 quantity) private pure {
        if (swap.inputCcy == Currency.Base && cashflow >= 0) {
            uint256 requiredBase = uint256(cashflow) - quantity;
            if ((-swap.input).toUint256() > requiredBase) revert InsufficientBaseOnOpen(requiredBase, -swap.input);
        }
    }

    function _applyFee(FlashLoanCallback memory cb, uint256 quantity) private returns (uint256 fee, Currency feeCcy) {
        (fee, feeCcy) = feeManager.applyFee(cb.owner, cb.positionId, quantity);
    }

    function _flash(
        IERC7399 provider,
        address loanReceiver,
        address asset,
        uint256 amount,
        bytes memory data,
        function(address, address, address, uint256, uint256, bytes memory) external returns (bytes memory) callback
    ) private returns (bytes memory result) {
        callbackHash = keccak256(data);
        result = provider.flash(loanReceiver, asset, amount, data, callback);
    }

    function _flashLoanCallback(bytes memory data) internal returns (FlashLoanCallback memory) {
        if (keccak256(data) != callbackHash) revert UnexpectedCallback();
        delete callbackHash;
        return data.decodeFlashLoanCallback();
    }

    function _moneyMarket(PositionId positionId) internal view returns (IMoneyMarket) {
        return positionFactory.moneyMarket(positionId);
    }

    function _depositBalance(IERC20 token, address owner) internal returns (uint256 deposited) {
        deposited = ERC20Lib.transferBalance(token, address(vault));
        if (deposited > 0) _vaultDeposit(token, owner, deposited);
    }

    function _handlePositiveCashflow(FlashLoanCallback memory cb) private {
        if (cb.cashflow > 0) _withdrawFromVault(cb.cashflowToken(), cb.owner, uint256(cb.cashflow), address(this));
    }

    function _handleNegativeCashflow(FlashLoanCallback memory cb) private {
        if (cb.cashflow < 0) {
            IERC20 _cashflowToken = cb.cashflowToken();
            _vaultDeposit({
                token: _cashflowToken,
                account: cb.owner,
                amount: ERC20Lib.transferOut(_cashflowToken, address(this), address(vault), cb.cashflow.abs())
            });
        }
    }

    function _handleRemainingQuote(address owner, InstrumentStorage memory _instrument, Trade memory _trade)
        private
        returns (int256 unusedQuoteCashflow)
    {
        uint256 remainingQuote = _depositBalance(_instrument.quote, owner);
        if (_trade.cashflowCcy == Currency.Quote && _trade.cashflow > 0 && remainingQuote > 0) {
            unusedQuoteCashflow = remainingQuote.toInt256();
        }
    }

    function _hasForwardPrice(FlashLoanCallback memory cb) private view returns (bool) {
        return !cb.positionId.isPerp() && !cb.positionId.isExpired() && cb.ep.swapAmount > 0;
    }

    function _vaultDeposit(IERC20 token, address account, uint256 amount) private {
        vault.deposit(token, account, amount);
    }

    function _vaultDepositTo(IERC20 token, address account, uint256 amount) private {
        vault.depositTo(token, account, amount);
    }

    function _withdrawFromVault(IERC20 token, address account, uint256 amount, address to) private {
        vault.withdraw(token, account, amount, to);
    }

    function _borrowFromMarket(IMoneyMarket mm, PositionId positionId, IERC20 asset, uint256 amount, address to)
        internal
        returns (uint256 actualAmount)
    {
        actualAmount = mm.borrow(positionId, asset, amount, to);
    }

    function _repayFromMarket(IMoneyMarket mm, PositionId positionId, IERC20 asset, uint256 amount)
        internal
        returns (uint256 actualAmount)
    {
        actualAmount = mm.repay(positionId, asset, amount);
    }

    function _forwardPriceOnOpen(FlashLoanCallback memory cb, Trade memory _trade, uint256 quantity, uint256 borrowed, uint256 repaid)
        private
        pure
        returns (uint256)
    {
        // Scenario 05 don't enter here since there was no swap
        // Scenarios 07, 11 don't enter here since it's just cashflow modification
        uint256 cost = _trade.cashflow == 0
            ? borrowed // Scenario 03
            : _trade.cashflow > 0
                ? _costForPositiveCashflowOnOpen(_trade, quantity, borrowed, repaid)
                : _costForNegativeCashflowOnOpen(_trade, quantity, borrowed);

        return cost.mulDiv(cb.instrument.baseUnit, _trade.quantity.toUint256());
    }

    function _costForPositiveCashflowOnOpen(Trade memory _trade, uint256 quantity, uint256 borrowed, uint256 repaid)
        private
        pure
        returns (uint256 cost)
    {
        if (_trade.cashflowCcy == Currency.Base) {
            if (_trade.swap.inputCcy == Currency.Base) {
                // Scenario 06
                // distributes swap cost to the quantity increase
                cost = quantity.mulDiv(_trade.swap.output.toUint256(), (-_trade.swap.input).toUint256());
            } else {
                // Scenarios 01, 04, 28
                // distributes swap cost to the cashflow + borrow cost to cover required swap input
                cost = _trade.cashflow.toUint256().mulDiv((-_trade.swap.input).toUint256(), _trade.swap.output.toUint256()) + borrowed;
            }
        } else {
            // Scenarios 02, 08, 09, 10, 29
            // whatever cashflow brought adjusting for debt delta
            cost = _trade.cashflow.toUint256() + borrowed - repaid;
        }
    }

    function _costForNegativeCashflowOnOpen(Trade memory _trade, uint256 quantity, uint256 borrowed) private pure returns (uint256 cost) {
        if (_trade.cashflowCcy == Currency.Base) {
            // Scenarios 12, 13
            // distributes borrow + swap cost to the quantity increase
            cost = quantity.mulDiv(borrowed, _trade.swap.output.toUint256());
        } else {
            // Scenarios 14, 15
            // distributes spot cost + debt delta to the cashflow
            uint256 spotCost = (-_trade.swap.input).toUint256();
            cost = spotCost.mulDiv(borrowed, spotCost + _trade.cashflow.abs());
        }
    }

    function _forwardPriceOnClose(FlashLoanCallback memory cb, Trade memory _trade, uint256 repaid, uint256 withdrawn)
        private
        pure
        returns (uint256)
    {
        // Scenario 27 don't enter here since there was no swap
        // Scenarios 25, 26 don't enter here since it's just cashflow modification
        uint256 cost = _trade.cashflow == 0
            ? repaid // Scenario 16
            : _trade.cashflow > 0
                ? _costForPositiveCashflowOnClose(_trade, repaid, withdrawn)
                : _costForNegativeCashflowOnClose(_trade, repaid, withdrawn);

        return cost.mulDiv(cb.instrument.baseUnit, (-_trade.quantity).toUint256());
    }

    function _costForPositiveCashflowOnClose(Trade memory _trade, uint256 repaid, uint256 withdrawn) private pure returns (uint256 cost) {
        if (_trade.cashflowCcy == Currency.Base) {
            // Scenario 17
            // distributes debt repayment to the quantity decrease
            cost = (withdrawn - _trade.fee).mulDiv(repaid, (-_trade.swap.input).toUint256());
        } else {
            // Scenario 18
            // distributes spot cost + debt delta to the cashflow
            uint256 spotCost = _trade.swap.output.toUint256();
            cost = spotCost.mulDiv(repaid, spotCost + _trade.cashflow.toUint256());
        }
    }

    function _costForNegativeCashflowOnClose(Trade memory _trade, uint256 repaid, uint256 withdrawn) private pure returns (uint256 cost) {
        if (_trade.cashflowCcy == Currency.Base) {
            if (repaid != 0) {
                // Scenarios 19, 23, 30
                // distributes debt repayment to the quantity decrease
                cost = (withdrawn - _trade.fee).mulDiv(repaid, (-_trade.swap.input).toUint256());
            } else {
                // Scenario 20
                // distributes swap cost to the quantity decrease
                cost = (withdrawn - _trade.fee).mulDiv((-_trade.swap.input).toUint256(), _trade.swap.output.toUint256());
            }
        } else {
            uint256 spotCost = _trade.swap.output.toUint256();
            if (repaid != 0) {
                // Scenarios 21, 24, 31
                // distributes spot cost + debt delta to the cashflow
                cost = spotCost.mulDiv(repaid, spotCost - (-_trade.cashflow).toUint256());
            } else {
                // Scenario 22
                // pure debt repayment
                cost = spotCost;
            }
        }
    }

    function _validateCashflowCcy(InstrumentStorage memory _instrument, Currency cashflowCcy, bool fullyClosing) internal pure {
        if (_instrument.base == _instrument.quote && cashflowCcy == Currency.Base) revert InvalidCashflowCcy();
        if (fullyClosing && cashflowCcy == Currency.None) revert CashflowCcyRequired();
    }

    function encodeTradeAndHash(Trade memory _trade) internal returns (bytes memory data) {
        data = abi.encode(_trade);
        tradeHash = keccak256(data);
    }

    function validateHashAndDecodeTrade(bytes memory data) internal returns (Trade memory) {
        if (keccak256(data) != tradeHash) revert UnexpectedTrade();
        delete tradeHash;
        return abi.decode(data, (Trade));
    }

    function claimRewards(PositionId positionId, address to) external override {
        if (positionNFT.exists(positionId)) positionNFT.validateModifyPositionPermissions(positionId);
        else if (lastOwner[positionId] != msg.sender) revert Unauthorised(msg.sender);

        (Symbol symbol,,,) = positionId.decode();
        InstrumentStorage storage _instrument = instruments[symbol];
        IMoneyMarket moneyMarket = _moneyMarket(positionId);
        moneyMarket.claimRewards(positionId, _instrument.base, _instrument.quote, to);
    }

    // ============================= Admin =========================

    function createInstrument(Symbol symbol, IERC20 base, IERC20 quote) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (instruments[symbol].base != IERC20(address(0))) revert InstrumentAlreadyExists(symbol);

        instruments[symbol].symbol = symbol;
        instruments[symbol].base = base;
        instruments[symbol].baseUnit = ERC20Lib.unit(base).toUint64();
        instruments[symbol].quote = quote;
        instruments[symbol].quoteUnit = ERC20Lib.unit(quote).toUint64();

        ERC20Lib.approveIfNecessary(base, address(feeManager));
        ERC20Lib.approveIfNecessary(quote, address(feeManager));

        emit InstrumentCreated(symbol, base, quote);
    }

    /// @dev temp function to apply permissions to already existent instruments
    function approveFeeManager(IERC20 token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ERC20Lib.approveIfNecessary(token, address(feeManager));
    }

    function setClosingOnly(Symbol symbol, bool closingOnly) external override onlyRole(OPERATOR_ROLE) {
        instruments[symbol].closingOnly = closingOnly;
        emit ClosingOnlySet(symbol, closingOnly);
    }

    function pause() external override onlyRole(EMERGENCY_BREAK_ROLE) {
        _pause();
    }

    function unpause() external override onlyRole(EMERGENCY_BREAK_ROLE) {
        _unpause();
    }

    // ============================= View =========================

    function instrument(Symbol symbol) external view override returns (Instrument memory instrument_) {
        InstrumentStorage memory i = instruments[symbol];
        instrument_.base = i.base;
        instrument_.baseUnit = i.baseUnit;
        instrument_.quote = i.quote;
        instrument_.quoteUnit = i.quoteUnit;
        instrument_.closingOnly = i.closingOnly;
    }

    // ============================= Admin ================================

    function _authorizeUpgrade(address) internal view override onlyRole(DEFAULT_ADMIN_ROLE) { }

}

function cashflowToken(Contango.FlashLoanCallback memory cb) pure returns (IERC20) {
    return cb.cashflowCcy == Currency.Base ? cb.instrument.base : cb.instrument.quote;
}

function encodeFlashLoanCallback(Contango.FlashLoanCallback memory cb) pure returns (bytes memory) {
    return abi.encode(cb);
}

function decodeFlashLoanCallback(bytes memory data) pure returns (Contango.FlashLoanCallback memory) {
    return abi.decode(data, (Contango.FlashLoanCallback));
}