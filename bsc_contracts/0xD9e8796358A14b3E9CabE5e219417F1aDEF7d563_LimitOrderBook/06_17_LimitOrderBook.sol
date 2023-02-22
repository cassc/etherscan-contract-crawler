//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Decimal} from "./utils/Decimal.sol";
import {SignedDecimal} from "./utils/SignedDecimal.sol";
import {DecimalERC20} from "./utils/DecimalERC20.sol";
import {MixedDecimal} from "./utils/MixedDecimal.sol";

import {IAmm} from "./interface/IAmm.sol";
import {IInsuranceFund} from "./interface/IInsuranceFund.sol";
import {ISmartWallet} from "./interface/ISmartWallet.sol";
import {ISmartWalletFactory} from "./interface/ISmartWalletFactory.sol";
import {ILimitOrderBook} from "./interface/ILimitOrderBook.sol";

contract LimitOrderBook is OwnableUpgradeable, DecimalERC20, ILimitOrderBook {
    using Decimal for Decimal.decimal;
    using SignedDecimal for SignedDecimal.signedDecimal;
    using MixedDecimal for SignedDecimal.signedDecimal;

    mapping(uint256 => LimitOrder) public orders;
    mapping(uint256 => RemainingOrderInfo) public remainingOrders;
    uint256 public orderLength;

    /* All smart wallets will be deployed by the factory - this allows you to get the
        contract address of the smart wallet for any trader */
    ISmartWalletFactory public factory;

    /* Other smart contracts that we interact with */
    IERC20 public quoteAsset;
    IInsuranceFund public insuranceFund;

    /* The minimum fee that needs to be attached to an order for it to be executed
        by a keeper. This can be adjusted at a later stage. This is to prevent spam attacks
        on the network */
    Decimal.decimal public minimumTipFee;

    function initialize(address _insuranceFund, uint256 _minimumTipFee)
        external
        initializer
    {
        __Ownable_init();
        insuranceFund = IInsuranceFund(_insuranceFund);
        quoteAsset = insuranceFund.quoteToken();

        minimumTipFee = Decimal.decimal(_minimumTipFee);
    }

    /*
     * FUNCTIONS TO ADD ORDERS
     */

    /*
     * @notice This function will create a limit order and store it within the contract.
     * Please see documentation for _createOrder()
     */
    function addLimitOrder(
        IAmm _asset,
        Decimal.decimal memory _limitPrice,
        SignedDecimal.signedDecimal memory _positionSize,
        Decimal.decimal memory _collateral,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _slippage,
        Decimal.decimal memory _tipFee,
        bool _reduceOnly,
        uint256 _expiry
    ) external {
        _createOrder(
            _asset,
            OrderType.LIMIT,
            _limitPrice,
            _positionSize,
            _collateral,
            _leverage,
            _slippage,
            _tipFee,
            _reduceOnly,
            _expiry
        );
    }

    /*
     * @notice This function will create a stop market order and store it within the contract.
     * Please see documentation for _createOrder()
     */
    function addStopOrder(
        IAmm _asset,
        Decimal.decimal memory _stopPrice,
        SignedDecimal.signedDecimal memory _positionSize,
        Decimal.decimal memory _collateral,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _slippage,
        Decimal.decimal memory _tipFee,
        bool _reduceOnly,
        uint256 _expiry
    ) external {
        _createOrder(
            _asset,
            OrderType.STOPLOSS,
            _stopPrice,
            _positionSize,
            _collateral,
            _leverage,
            _slippage,
            _tipFee,
            _reduceOnly,
            _expiry
        );
    }

    /*
     * @notice Will create an advanced order and store it within the contract
     * @param _asset the AMM address for the asset being traded
     * @param _orderType the type of order (as enum)
     * @param _stopPrice the STOP trigger price
     * @param _limitPrice the LIMIT trigger price
     * @param _positionSize the size of the order in base asset
     * @param _collateral the amount of margin/collateral that will be used for order
     * @param _leverage the maximum leverage acceptable for trade
     * @param _slippage the minimum amount of base asset that the trader will accept
     *    This is subtly different to _positionSize. Let us assume that the trader
     *    has created an order to buy 1 BTC below 50K. The price of bitcoin hits
     *    49,980 and so an order gets executed. His actual execution price may be
     *    50,500 (due to price impact). He can adjust the slippage parameter to
     *    decide whether he wants the transaction to be executed at this price or not.
     *    If slippage is set to 0, then any price is accepted.
     * @param _tipFee is the fee that will go to the keeper that executes the order.
     *    This fee is taken as soon as the order is created.
     * @param _reduceOnly whether the order is reduceonly or not
     * @param _expiry when the order expires (block timestamp). If this variable is
     *    0 then it will never expire.
     */
    function _createOrder(
        IAmm _asset,
        OrderType _orderType,
        Decimal.decimal memory _limitPrice,
        SignedDecimal.signedDecimal memory _positionSize,
        Decimal.decimal memory _collateral,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _slippage,
        Decimal.decimal memory _tipFee,
        bool _reduceOnly,
        uint256 _expiry
    ) internal {
        requireNonZeroInput(_limitPrice, "LimitOrderBook: zero price");
        //Check expiry parameter
        require(
            ((_expiry == 0) || (block.timestamp < _expiry)),
            "LimitOrderBook: invalid expiry"
        );
        //Check whether fee is sufficient
        require(
            _tipFee.cmp(minimumTipFee) >= 0,
            "LimitOrderBook: less than min"
        );
        //Check on the smart wallet factory whether this trader has a smart wallet
        address _smartWallet = factory.getSmartWallet(msg.sender);
        require(_smartWallet != address(0), "LimitOrderBook: No smart wallet");
        //Need to make sure the asset is actually a PERP asset
        require(
            insuranceFund.isExistedAmm(_asset),
            "LimitOrderBook: invalid amm"
        );
        //Sanity checks
        requireNonZeroInput(_positionSize.abs(), "LimitOrderBook: zero size");
        require(
            _slippage.cmp(Decimal.one()) != 1,
            "LimitOrderBook: invalid slippage"
        );

        requireNonZeroInput(_collateral, "LimitOrderBook: zero collateral");
        require(_leverage.cmp(Decimal.one()) != -1, "Minimum 1x leverage");
        if (_tipFee.toUint() != 0) {
            //Take fee from user - user needs to approve this contract to spend their asset first
            _transferFrom(quoteAsset, _smartWallet, address(this), _tipFee);
        }

        uint256 _orderLength = orderLength;
        //Emit event on order creation
        emit OrderCreated(msg.sender, _orderLength);
        //Add values to array
        orders[_orderLength] = LimitOrder({
            asset: address(_asset),
            trader: msg.sender,
            orderType: _orderType,
            limitPrice: _limitPrice,
            orderSize: _positionSize,
            collateral: _collateral,
            leverage: _leverage,
            slippage: _slippage,
            tipFee: _tipFee,
            reduceOnly: _reduceOnly,
            stillValid: true,
            expiry: _expiry
        });

        orderLength = _orderLength + 1;
    }

    /*
     * FUNCTIONS TO INTERACT WITH ORDERS (EXECUTE/DELETE/ETC)
     */

    /*
     * @notice Delete an order
     */
    function deleteOrder(uint256 order_id) external onlyMyOrder(order_id) {
        emit OrderCancelled(msg.sender, order_id);

        (
            ILimitOrderBook.LimitOrder memory _limitOrder,
            ILimitOrderBook.RemainingOrderInfo memory _remainingOrder
        ) = getLimitOrder(order_id);

        Decimal.decimal memory tipFee;

        if (_remainingOrder.remainingTipFee.toUint() == 0) {
            tipFee = _limitOrder.tipFee;
        } else {
            tipFee = _remainingOrder.remainingTipFee;
        }

        if (tipFee.toUint() != 0) {
            // Transfer remaining tip fee back to user
            address _smartWallet = factory.getSmartWallet(msg.sender);
            _transfer(quoteAsset, _smartWallet, tipFee);
        }

        delete orders[order_id];
        delete remainingOrders[order_id];
    }

    /*
     * @notice Execute an order using the order_id
     * All the logic verifying the order can be successfully executed occurs on the SmartWallet.sol contract
     */
    function execute(uint256 order_id, Decimal.decimal memory maxQuoteAsset)
        external
        onlyValidOrder(order_id)
    {
        //First check that the order hasn't been cancelled/already been executed
        LimitOrder memory order = orders[order_id];
        require(
            ((order.expiry == 0) || (block.timestamp < order.expiry)),
            "LimitOrderBook: order expired"
        );
        address _trader = order.trader;
        //Get the smart wallet of the trader from the factory contract
        address _smartwallet = factory.getSmartWallet(order.trader);
        //Try and execute the order (should return true if successful)
        (
            SignedDecimal.signedDecimal memory exchangedPositionSize,
            Decimal.decimal memory exchangedQuoteAmount
        ) = ISmartWallet(_smartwallet).executeOrder(order_id, maxQuoteAsset);

        _afterOrderExecution(
            _trader,
            msg.sender,
            order_id,
            exchangedPositionSize,
            exchangedQuoteAmount,
            maxQuoteAsset.toUint() == 0
        );
    }

    function _afterOrderExecution(
        address trader,
        address operator,
        uint256 order_id,
        SignedDecimal.signedDecimal memory exchangedPositionSize,
        Decimal.decimal memory exchangedQuoteAmount,
        bool filledAll
    ) internal {
        (
            ILimitOrderBook.LimitOrder memory _limitOrder,
            ILimitOrderBook.RemainingOrderInfo memory _remainingOrder
        ) = getLimitOrder(order_id);

        SignedDecimal.signedDecimal memory orderSize;
        Decimal.decimal memory collateral;
        Decimal.decimal memory tipFee;

        if (_remainingOrder.remainingOrderSize.toInt() == 0) {
            orderSize = _limitOrder.orderSize;
            collateral = _limitOrder.collateral;
            tipFee = _limitOrder.tipFee;
        } else {
            orderSize = _remainingOrder.remainingOrderSize;
            collateral = _remainingOrder.remainingCollateral;
            tipFee = _remainingOrder.remainingTipFee;
        }

        Decimal.decimal memory payableTipFee;
        Decimal.decimal memory usedCollateral = exchangedQuoteAmount.divD(
            _limitOrder.leverage
        );

        if (
            filledAll ||
            orderSize.abs().toUint() <= exchangedPositionSize.abs().toUint() ||
            collateral.toUint() <= usedCollateral.toUint()
        ) {
            delete orders[order_id];
            delete remainingOrders[order_id];

            payableTipFee = tipFee;
            filledAll = true;
        } else {
            remainingOrders[order_id].remainingOrderSize = orderSize.subD(
                exchangedPositionSize
            );
            remainingOrders[order_id].remainingCollateral = collateral.subD(
                usedCollateral
            );

            payableTipFee = tipFee.mulD(exchangedPositionSize.abs()).divD(
                orderSize.abs()
            );

            remainingOrders[order_id].remainingTipFee = tipFee.subD(
                payableTipFee
            );
        }

        if (payableTipFee.toUint() != 0) {
            _transfer(quoteAsset, operator, payableTipFee);
        }

        emit OrderFilled(
            trader,
            operator,
            order_id,
            filledAll,
            exchangedPositionSize.toInt(),
            exchangedQuoteAmount.toUint()
        );
    }

    /*
     * VIEW FUNCTIONS
     */
    function getLimitOrder(uint256 id)
        public
        view
        override
        onlyValidOrder(id)
        returns (LimitOrder memory, RemainingOrderInfo memory)
    {
        return (orders[id], remainingOrders[id]);
    }

    function getLimitOrderParams(uint256 id)
        external
        view
        override
        onlyValidOrder(id)
        returns (
            address,
            address,
            OrderType,
            bool,
            bool,
            uint256
        )
    {
        LimitOrder memory order = orders[id];
        return (
            order.asset,
            order.trader,
            order.orderType,
            order.reduceOnly,
            order.stillValid,
            order.expiry
        );
    }

    /*
     * ADMIN / SETUP FUNCTIONS
     */

    function setFactory(address _addr) external onlyOwner {
        factory = ISmartWalletFactory(_addr);
    }

    function changeMinimumFee(Decimal.decimal memory _fee) external onlyOwner {
        minimumTipFee = _fee;
    }

    /*
     * MODIFIERS
     */

    modifier onlyValidOrder(uint256 order_id) {
        require(order_id < orderLength, "LimitOrderBook: invalid ID");
        LimitOrder memory order = orders[order_id];
        require(order.stillValid, "LimitOrderBook: No longer valid");
        _;
    }

    modifier onlyMyOrder(uint256 order_id) {
        require(
            msg.sender == orders[order_id].trader,
            "LimitOrderBook: Not your order"
        );
        _;
    }

    function requireNonZeroInput(
        Decimal.decimal memory _decimal,
        string memory errorMessage
    ) private pure {
        require(_decimal.toUint() != 0, errorMessage);
    }
}