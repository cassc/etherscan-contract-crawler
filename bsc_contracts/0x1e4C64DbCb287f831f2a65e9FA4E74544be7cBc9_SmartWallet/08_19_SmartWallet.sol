// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import {Decimal} from "./utils/Decimal.sol";
import {SignedDecimal} from "./utils/SignedDecimal.sol";
import {MixedDecimal} from "./utils/MixedDecimal.sol";

import {IAmm} from "./interface/IAmm.sol";
import {IClearingHouse} from "./interface/IClearingHouse.sol";
import {ISmartWallet} from "./interface/ISmartWallet.sol";
import {ISmartWalletFactory} from "./interface/ISmartWalletFactory.sol";
import {ILimitOrderBook} from "./interface/ILimitOrderBook.sol";

contract SmartWallet is Initializable, ISmartWallet, Pausable {
    using Decimal for Decimal.decimal;
    using SignedDecimal for SignedDecimal.signedDecimal;
    using Address for address;
    using SafeERC20 for IERC20;

    event ExecuteMarketOrder(
        address indexed trader,
        address indexed asset,
        SignedDecimal.signedDecimal orderSize,
        Decimal.decimal collateral,
        Decimal.decimal leverage,
        Decimal.decimal slippage
    );

    event ExecuteClosePosition(
        address indexed trader,
        address indexed asset,
        Decimal.decimal percentage,
        SignedDecimal.signedDecimal exchangedPositionSize,
        Decimal.decimal exchangedQuoteAmount
    );

    // Store addresses of smart contracts that we will be interacting with
    ILimitOrderBook public orderBook;
    ISmartWalletFactory public factory;
    IClearingHouse public clearingHouse;
    IERC20 public quoteToken;

    address public override owner;

    uint256 public lastWithdrawDayIdx;
    uint256 public lastDayWithdrawnAmount;

    modifier onlyOrderBook() {
        require(
            msg.sender == address(orderBook),
            "SmartWallet: caller is not order book"
        );
        _;
    }

    function initialize(
        address _clearingHouse,
        address _limitOrderBook,
        address _owner
    ) external override initializer {
        clearingHouse = IClearingHouse(_clearingHouse);
        orderBook = ILimitOrderBook(_limitOrderBook);
        factory = ISmartWalletFactory(msg.sender);
        owner = _owner;

        quoteToken = clearingHouse.quoteToken();
    }

    /*
     * @notice allows the owner of the smart wallet to execute any transaction
     *  on an external smart contract. The external smart contract must be whitelisted
     *  otherwise this function will revert
     *  This utilises functions from OpenZeppelin's Address.sol
     * @param target the address of the smart contract to interact with (will revert
     *    if this is not a valid smart contract)
     * @param callData the data bytes of the function and parameters to execute
     *    Can use encodeFunctionData() from ethers.js
     * @param value the ether value to attach to the function call (can be 0)
     */

    function executeCall(
        address target,
        bytes calldata callData,
        uint256 value
    ) external payable override onlyOwner returns (bytes memory) {
        require(target.isContract(), "SmartWallet: call to non-contract");
        require(factory.isWhitelisted(target), "SmartWallet: not whitelisted");
        require(value == msg.value, "SmartWallet: incorrect value");
        return target.functionCallWithValue(callData, value);
    }

    function approveQuoteToken(address spender, uint256 amount)
        external
        override
        onlyOwner
    {
        quoteToken.safeApprove(spender, amount);
    }

    function transferQuoteToken(address to, uint256 amount)
        external
        override
        onlyOwner
    {
        uint256 dailyWithdrawLimit = factory.dailyWithdrawLimit();

        uint256 dayIdx = block.timestamp / 1 days;

        uint256 _lastDayWithdrawnAmount = lastWithdrawDayIdx == dayIdx
            ? lastDayWithdrawnAmount
            : 0;

        _lastDayWithdrawnAmount += amount;
        require(
            dailyWithdrawLimit == 0 ||
                _lastDayWithdrawnAmount <= dailyWithdrawLimit,
            "SmartWallet: Exceed daily withdraw limit"
        );

        lastDayWithdrawnAmount = _lastDayWithdrawnAmount;
        lastWithdrawDayIdx = dayIdx;

        quoteToken.safeTransfer(to, amount);
    }

    function executeMarketOrder(
        IAmm _asset,
        SignedDecimal.signedDecimal memory _orderSize,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _slippage
    ) external override onlyOwner whenNotPaused {
        (
            SignedDecimal.signedDecimal memory exchangedPositionSize,
            Decimal.decimal memory exchangedQuoteAmount
        ) = _handleOpenPosition(
                _asset,
                _orderSize,
                Decimal.decimal(0),
                _leverage,
                _slippage,
                true
            );

        emit ExecuteMarketOrder(
            owner,
            address(_asset),
            exchangedPositionSize,
            exchangedQuoteAmount.divD(_leverage),
            _leverage,
            _slippage
        );
    }

    function executeClosePosition(IAmm _asset, Decimal.decimal memory _slippage)
        external
        override
        onlyOwner
        whenNotPaused
    {
        (
            SignedDecimal.signedDecimal memory exchangedPositionSize,
            Decimal.decimal memory exchangedQuoteAmount
        ) = _handleClosePosition(_asset, Decimal.one(), _slippage);

        emit ExecuteClosePosition(
            owner,
            address(_asset),
            Decimal.one(),
            exchangedPositionSize,
            exchangedQuoteAmount
        );
    }

    function executeClosePartialPosition(
        IAmm _asset,
        Decimal.decimal memory _percentage,
        Decimal.decimal memory _slippage
    ) external override onlyOwner whenNotPaused {
        (
            SignedDecimal.signedDecimal memory exchangedPositionSize,
            Decimal.decimal memory exchangedQuoteAmount
        ) = _handleClosePosition(_asset, _percentage, _slippage);

        emit ExecuteClosePosition(
            owner,
            address(_asset),
            _percentage,
            exchangedPositionSize,
            exchangedQuoteAmount
        );
    }

    function executeAddMargin(
        IAmm _asset,
        Decimal.decimal calldata _addedMargin
    ) external override onlyOwner whenNotPaused {
        _handleAddMargin(_asset, _addedMargin);
    }

    function executeRemoveMargin(
        IAmm _asset,
        Decimal.decimal calldata _removedMargin
    ) external override onlyOwner whenNotPaused {
        _handleRemoveMargin(_asset, _removedMargin);
    }

    function pauseWallet() external onlyOwner {
        _pause();
    }

    function unpauseWallet() external onlyOwner {
        _unpause();
    }

    /*
     * @notice Will execute an order from the limit order book. Note that the only
     *  way to call this function is via the LimitOrderBook where you call execute().
     * @param order_id is the ID of the order to execute
     */
    function executeOrder(uint256 order_id, Decimal.decimal memory maxNotional)
        external
        virtual
        override
        whenNotPaused
        onlyOrderBook
        returns (SignedDecimal.signedDecimal memory, Decimal.decimal memory)
    {
        //Get some of the parameters
        (
            ,
            ,
            ILimitOrderBook.OrderType _orderType,
            ,
            bool _stillValid,

        ) = orderBook.getLimitOrderParams(order_id);

        //Make sure the order is still valid
        require(_stillValid, "SmartWallet: Order no longer valid");
        //Perform function depending on the type of order

        if (_orderType == ILimitOrderBook.OrderType.LIMIT) {
            return _executeLimitOrder(order_id, maxNotional);
        } else if (_orderType == ILimitOrderBook.OrderType.STOPLOSS) {
            return _executeStopOrder(order_id, maxNotional);
        }
    }

    function minD(Decimal.decimal memory a, Decimal.decimal memory b)
        internal
        pure
        returns (Decimal.decimal memory)
    {
        return (a.cmp(b) >= 1) ? b : a;
    }

    function _handleOpenPosition(
        IAmm _asset,
        SignedDecimal.signedDecimal memory _orderSize,
        Decimal.decimal memory _collateral,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _slippage,
        bool isMarketOrder
    )
        internal
        returns (SignedDecimal.signedDecimal memory, Decimal.decimal memory)
    {
        IAmm _asset_ = _asset;
        SignedDecimal.signedDecimal memory _orderSize_ = _orderSize;
        Decimal.decimal memory _collateral_ = _collateral;
        Decimal.decimal memory _leverage_ = _leverage;
        Decimal.decimal memory _slippage_ = _slippage;

        //Establish how much leverage will be needed for that order based on the
        //amount of collateral and the maximum leverage the user was happy with.
        bool _isLong = _orderSize_.isNegative() ? false : true;

        {
            Decimal.decimal memory _size = _orderSize_.abs();
            Decimal.decimal memory _quote = (
                _asset_.getOutputPrice(
                    _isLong ? IAmm.Dir.REMOVE_FROM_AMM : IAmm.Dir.ADD_TO_AMM,
                    _size
                )
            );
            if (isMarketOrder) {
                _collateral_ = _quote.divD(_leverage_);
            } else {
                Decimal.decimal memory _offset = Decimal.decimal(1); //Need to add one wei for rounding
                _leverage_ = minD(
                    _quote.divD(_collateral_).addD(_offset),
                    _leverage_
                );
            }
        }

        Decimal.decimal memory fee = clearingHouse.calcFee(
            _collateral_.mulD(_leverage_)
        );
        _approve(address(clearingHouse), fee.addD(_collateral_));
        (
            SignedDecimal.signedDecimal memory exchangedPositionSize,
            Decimal.decimal memory exchangedQuoteAmount
        ) = clearingHouse.openPosition(
                _asset_,
                _isLong ? IClearingHouse.Side.BUY : IClearingHouse.Side.SELL,
                _collateral_,
                _leverage_,
                _slippage_
            );

        return (exchangedPositionSize, exchangedQuoteAmount);
    }

    function _handleAddMargin(
        IAmm _asset,
        Decimal.decimal calldata _addedMargin
    ) internal {
        _approve(address(clearingHouse), _addedMargin);
        clearingHouse.addMargin(_asset, _addedMargin);
    }

    function _handleRemoveMargin(
        IAmm _asset,
        Decimal.decimal calldata _removedMargin
    ) internal {
        clearingHouse.removeMargin(_asset, _removedMargin);
    }

    function _calcBaseAssetAmountLimit(
        Decimal.decimal memory _positionSize,
        bool _isLong,
        Decimal.decimal memory _slippage
    ) internal pure returns (Decimal.decimal memory) {
        if (_slippage.cmp(Decimal.one()) == 0) {
            return Decimal.decimal(0);
        }
        Decimal.decimal memory factor;
        require(_slippage.cmp(Decimal.one()) == -1, "Slippage must be %");
        if (_isLong) {
            //base amount must be greater than base amount limit
            factor = Decimal.one().subD(_slippage);
        } else {
            //base amount must be less than base amount limit
            factor = Decimal.one().addD(_slippage);
        }
        return factor.mulD(_positionSize);
    }

    /*
        OPEN LONG
        BASE ASSET LIMIT = POSITION SIZE - SLIPPAGE
        OPEN SHORT
        BASE ASSET LIMIT = POSITION SIZE + SLIPPAGE
        CLOSE LONG
        QUOTE ASSET LIMIT = VALUE - SLIPPAGE
        CLOSE SHORT
        QUOTE ASSET LIMIT = VALUE + SLIPPAGE
    */

    function _calcQuoteAssetAmountLimit(
        IAmm _asset,
        Decimal.decimal memory _targetPrice,
        bool _isLong,
        Decimal.decimal memory _slippage
    ) internal view returns (Decimal.decimal memory) {
        IClearingHouse.Position memory oldPosition = clearingHouse.getPosition(
            _asset,
            address(this)
        );
        SignedDecimal.signedDecimal memory oldPositionSize = oldPosition.size;
        Decimal.decimal memory value = oldPositionSize.abs().mulD(_targetPrice);
        Decimal.decimal memory factor;
        if (_slippage.cmp(Decimal.one()) == 0) {
            return Decimal.decimal(0);
        }
        require(_slippage.cmp(Decimal.one()) == -1, "Slippage must be %");
        if (_isLong) {
            //quote amount must be less than quote amount limit
            factor = Decimal.one().addD(_slippage);
        } else {
            //quote amount must be greater than quote amount limit
            factor = Decimal.one().subD(_slippage);
        }
        return factor.mulD(value);
    }

    function _handleClosePosition(
        IAmm _asset,
        Decimal.decimal memory _percentage,
        Decimal.decimal memory _slippage
    )
        internal
        returns (
            SignedDecimal.signedDecimal memory exchangedPositionSize,
            Decimal.decimal memory exchangedQuoteAmount
        )
    {
        require(
            _percentage.cmp(Decimal.one()) <= 0,
            "SmartWallet: Invalid percentage"
        );

        IClearingHouse.Position memory oldPosition = clearingHouse.getPosition(
            _asset,
            address(this)
        );
        SignedDecimal.signedDecimal memory oldPositionSize = oldPosition.size;
        Decimal.decimal memory _quoteAsset = _asset.getOutputPrice(
            oldPositionSize.toInt() > 0
                ? IAmm.Dir.ADD_TO_AMM
                : IAmm.Dir.REMOVE_FROM_AMM,
            oldPositionSize.abs().mulD(_percentage)
        );
        Decimal.decimal memory fee = clearingHouse.calcFee(_quoteAsset);
        _approve(address(clearingHouse), fee);

        (exchangedPositionSize, exchangedQuoteAmount) = clearingHouse
            .closePartialPosition(_asset, _percentage, _slippage);
    }

    /*
     * @notice Get close position percentage
     * @param _asset the AMM for the asset
     * @param _orderSize the size of the order (note: negative are SELL/SHORT)
     */
    function _closePositionPercentage(
        IAmm _asset,
        SignedDecimal.signedDecimal memory _orderSize
    ) internal view returns (Decimal.decimal memory) {
        //Get the size of the users current position
        IClearingHouse.Position memory _currentPosition = clearingHouse
            .getPosition(IAmm(_asset), address(this));
        SignedDecimal.signedDecimal memory _currentSize = _currentPosition.size;
        //If the user has no position for this asset, then cannot execute a reduceOnly order
        require(
            _currentSize.abs().toUint() != 0,
            "#reduceOnly: current size is 0"
        );
        //If the direction of the order is opposite to the users current position
        if (_orderSize.isNegative() != _currentSize.isNegative()) {
            //The size of the order is large enough to open a reverse position,
            //therefore we should close it instead
            if (_orderSize.abs().cmp(_currentSize.abs()) == -1) {
                return _orderSize.abs().divD(_currentSize.abs());
            } else {
                return Decimal.one();
            }
        } else {
            //User is trying to increase the size of their position
            revert("#reduceOnly: cannot increase size of position");
        }
    }

    /*
     * @notice internal position to execute limit order - note that you need to
     *  check that this is a limit order before calling this function
     */
    function _executeLimitOrder(
        uint256 order_id,
        Decimal.decimal memory maxNotional
    )
        internal
        returns (SignedDecimal.signedDecimal memory, Decimal.decimal memory)
    {
        //Get information of limit order
        (
            Decimal.decimal memory _limitPrice,
            SignedDecimal.signedDecimal memory _orderSize,
            Decimal.decimal memory _collateral,
            Decimal.decimal memory _leverage,
            ,
            address _asset,
            bool _reduceOnly
        ) = _getOrderDetails(order_id);

        // If it's take profit, don't validate price
        if (!_reduceOnly) {
            _validatePrice(IAmm(_asset));
        }

        Decimal.decimal memory _maxNotional = maxNotional;

        //Establish whether long or short
        bool isLong = _orderSize.isNegative() ? false : true;
        //Get the current spot price of the asset
        Decimal.decimal memory _markPrice = IAmm(_asset).getSpotPrice();
        require(
            _markPrice.cmp(Decimal.zero()) >= 1,
            "SmartWallet: Error getting mark price"
        );

        //Check whether price conditions have been met:
        //  LIMIT BUY: mark price <= limit price
        //  LIMIT SELL: mark price >= limit price
        require(
            (_limitPrice.cmp(_markPrice)) != (isLong ? -1 : int128(1)),
            "SmartWallet: Invalid limit order condition"
        );

        return
            _openOrClosePosition(
                _asset,
                _orderSize,
                _collateral,
                _leverage,
                _maxNotional,
                _reduceOnly
            );
    }

    function _executeStopOrder(
        uint256 order_id,
        Decimal.decimal memory maxNotional
    )
        internal
        returns (SignedDecimal.signedDecimal memory, Decimal.decimal memory)
    {
        //Get information of stop order
        (
            Decimal.decimal memory _limitPrice,
            SignedDecimal.signedDecimal memory _orderSize,
            Decimal.decimal memory _collateral,
            Decimal.decimal memory _leverage,
            ,
            address _asset,
            bool _reduceOnly
        ) = _getOrderDetails(order_id);

        _validatePrice(IAmm(_asset));

        Decimal.decimal memory _maxNotional = maxNotional;

        //Establish whether long or short
        bool isLong = _orderSize.isNegative() ? false : true;
        //Get the current spot price of the asset
        Decimal.decimal memory _markPrice = IAmm(_asset).getSpotPrice();
        require(
            _markPrice.cmp(Decimal.zero()) >= 1,
            "Error getting mark price"
        );
        //Check whether price conditions have been met:
        //  STOP BUY: mark price > stop price
        //  STOP SELL: mark price < stop price
        require(
            (_markPrice.cmp(_limitPrice)) != (isLong ? -1 : int128(1)),
            "SmartWallet: Invalid stop order condition"
        );

        return
            _openOrClosePosition(
                _asset,
                _orderSize,
                _collateral,
                _leverage,
                _maxNotional,
                _reduceOnly
            );
    }

    function _openOrClosePosition(
        address _asset,
        SignedDecimal.signedDecimal memory _orderSize,
        Decimal.decimal memory _collateral,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory maxNotional,
        bool _close
    )
        internal
        returns (SignedDecimal.signedDecimal memory, Decimal.decimal memory)
    {
        SignedDecimal.signedDecimal memory _orderSize_ = _orderSize;
        if (_close) {
            IAmm.Dir _dirOfQuote = _orderSize.isNegative()
                ? IAmm.Dir.REMOVE_FROM_AMM
                : IAmm.Dir.ADD_TO_AMM;
            if (maxNotional.toUint() != 0) {
                Decimal.decimal memory maxBaseAsset = IAmm(_asset)
                    .getInputPrice(_dirOfQuote, maxNotional);
                if (_orderSize_.abs().cmp(maxBaseAsset) == 1) {
                    if (_orderSize.isNegative()) {
                        _orderSize_ = MixedDecimal
                            .fromDecimal(maxBaseAsset)
                            .mulScalar(-1);
                    } else {
                        _orderSize_ = MixedDecimal.fromDecimal(maxBaseAsset);
                    }
                }
            }

            return
                _handleClosePosition(
                    IAmm(_asset),
                    _closePositionPercentage(IAmm(_asset), _orderSize_),
                    Decimal.decimal(0)
                );
        } else {
            Decimal.decimal memory totalNotional = _collateral.mulD(_leverage);
            if (
                maxNotional.toUint() != 0 &&
                maxNotional.cmp(totalNotional) == -1
            ) {
                Decimal.decimal memory percentage = maxNotional.divD(
                    totalNotional
                );
                _orderSize = _orderSize.mulD(
                    MixedDecimal.fromDecimal(percentage)
                );
                _collateral = _collateral.mulD(percentage);
            }
            return
                _handleOpenPosition(
                    IAmm(_asset),
                    _orderSize_,
                    _collateral,
                    _leverage,
                    Decimal.decimal(0),
                    false
                );
        }
    }

    function _getOrderDetails(uint256 order_id)
        internal
        view
        returns (
            Decimal.decimal memory limitPrice,
            SignedDecimal.signedDecimal memory orderSize,
            Decimal.decimal memory collateral,
            Decimal.decimal memory leverage,
            Decimal.decimal memory slippage,
            address asset,
            bool reduceOnly
        )
    {
        (
            ILimitOrderBook.LimitOrder memory _limitOrder,
            ILimitOrderBook.RemainingOrderInfo memory _remainingOrder
        ) = orderBook.getLimitOrder(order_id);

        limitPrice = _limitOrder.limitPrice;
        leverage = _limitOrder.leverage;
        slippage = _limitOrder.slippage;
        asset = _limitOrder.asset;
        reduceOnly = _limitOrder.reduceOnly;
        if (_remainingOrder.remainingOrderSize.toInt() == 0) {
            orderSize = _limitOrder.orderSize;
            collateral = _limitOrder.collateral;
        } else {
            orderSize = _remainingOrder.remainingOrderSize;
            collateral = _remainingOrder.remainingCollateral;
        }
    }

    function _validatePrice(IAmm amm) internal view {
        Decimal.decimal memory spotPrice = amm.getSpotPrice();
        Decimal.decimal memory indexPrice = amm.getUnderlyingPrice();

        Decimal.decimal memory delta = MixedDecimal
            .subD(MixedDecimal.fromDecimal(spotPrice), indexPrice)
            .abs();
        require(
            delta.divD(indexPrice).toUint() < 3e16,
            "SmartWallet: Too much price difference"
        );
    }

    function _approve(address spender, Decimal.decimal memory amount) internal {
        if (amount.toUint() != 0) {
            quoteToken.safeApprove(spender, 0);
            quoteToken.safeApprove(spender, amount.toUint());
        }
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}