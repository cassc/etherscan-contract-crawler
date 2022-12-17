/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "./IOrderbook.sol";

contract MYSTOrderbookV3 is Initializable, IOrderbook, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public quoteToken;
    address public baseToken;

    uint256 public orderFee;
    address public feeReceiver;
    uint256 public claimableMxstFee;
    uint256 public claimableBusdFee;

    uint256 public buyStep;
    uint256 public sellStep;
    uint256 public buyCount;
    uint256 public sellCount;
    uint256 public mxstPrice;
    uint256 public maxBuyPrice;
    uint256 public orderLockDuration;

    mapping(uint256 => Order) public buyOrders;
    mapping(uint256 => Order) public sellOrders;
    mapping(address => uint256[]) public ownedBuyOrders;
    mapping(address => uint256[]) public ownedSellOrders;

    uint256 public constant PERCENT_DENOMINATOR = 10000;

    /**
     * @notice Constructor
     */
    function initialize(address _baseToken, address _quoteToken)
        public
        initializer
    {
        __Ownable_init();

        baseToken = _baseToken;
        quoteToken = _quoteToken;

        orderLockDuration = 10 minutes;
        orderFee = 500;
        feeReceiver = 0x5E4Cf6aCe91F797cdbD277f6773d8a1EFb029530;

        mxstPrice = 2 * (10**IERC20MetadataUpgradeable(baseToken).decimals());
        _transferOwnership(0x5E4Cf6aCe91F797cdbD277f6773d8a1EFb029530);
    }

    /**
     * @notice Place buy order.
     */
    function placeBuyOrder(uint256 amountOfBaseToken) external {
        require(amountOfBaseToken != 0, "Invalid amount!");
        IERC20Upgradeable(baseToken).safeTransferFrom(
            msg.sender,
            address(this),
            amountOfBaseToken
        );

        uint256 ordFee = takeDexFee(amountOfBaseToken, true);
        amountOfBaseToken = amountOfBaseToken.sub(ordFee);
        /**
         * @notice if has order in sell book, and price >= min sell price
         */
        uint256 mxstToSend = busdToMxst(amountOfBaseToken);
        uint256 orderId = ++buyCount;
        buyOrders[orderId].maker = msg.sender;
        buyOrders[orderId].amount = amountOfBaseToken.add(ordFee);
        buyOrders[orderId].remAmount = mxstToSend;
        buyOrders[orderId].createdAt = block.timestamp;
        buyOrders[orderId].updatedAt = block.timestamp;
        buyOrders[orderId].status = OrdStatus.PENDING;

        uint256 counter = sellStep == 0 ? 1 : sellStep;
        while (mxstToSend > 0 && counter <= sellCount) {
            Order storage curAskOrder = sellOrders[counter];
            // Check if order alredy cancelled
            if (curAskOrder.status == OrdStatus.CANCELLED) {
                sellStep = counter + 1;
                counter++;
                continue;
            }

            // process order if matched any
            uint256 busdToSend;
            if (busdToMxst(curAskOrder.remAmount) >= mxstToSend) {
                busdToSend = mxstToBusd(mxstToSend);
                curAskOrder.remAmount = curAskOrder.remAmount.sub(busdToSend);
                mxstToSend = 0;
            } else {
                busdToSend = curAskOrder.remAmount;
                mxstToSend = mxstToSend.sub(busdToMxst(curAskOrder.remAmount));
                curAskOrder.remAmount = 0;
            }

            if (curAskOrder.remAmount == 0) {
                curAskOrder.status = OrdStatus.FILLED;
                sellStep = counter + 1;
            }
            curAskOrder.updatedAt = block.timestamp;

            IERC20Upgradeable(baseToken).transfer(
                curAskOrder.maker,
                busdToSend
            );
            counter++;
        }

        uint256 matchedMxst = buyOrders[orderId].remAmount.sub(mxstToSend);
        buyOrders[orderId].remAmount = mxstToSend;
        if (buyOrders[orderId].remAmount == 0) {
            buyOrders[orderId].status = OrdStatus.FILLED;
            buyOrders[orderId].updatedAt = block.timestamp;
            buyStep = orderId + 1;
        }
        ownedBuyOrders[msg.sender].push(orderId);
        if (matchedMxst != 0) {
            IERC20Upgradeable(quoteToken).transfer(
                buyOrders[orderId].maker,
                matchedMxst
            );
        }
        emit PlaceBuyOrder(orderId, msg.sender, mxstPrice, amountOfBaseToken);
    }

    /**
     * @notice Place buy order.
     */
    function placeSellOrder(uint256 amountOfTradeToken) external {
        require(amountOfTradeToken != 0, "Invalid amount!");
        IERC20Upgradeable(quoteToken).safeTransferFrom(
            msg.sender,
            address(this),
            amountOfTradeToken
        );

        uint256 ordFee = takeDexFee(amountOfTradeToken, false);
        amountOfTradeToken = amountOfTradeToken.sub(ordFee);

        /**
         * @notice if has order in buy book, and price <= max buy price
         */
        uint256 busdToSend = mxstToBusd(amountOfTradeToken);
        uint256 orderId = ++sellCount;
        sellOrders[orderId].maker = msg.sender;
        sellOrders[orderId].amount = amountOfTradeToken.add(ordFee);
        sellOrders[orderId].remAmount = busdToSend;
        sellOrders[orderId].createdAt = block.timestamp;
        sellOrders[orderId].updatedAt = block.timestamp;
        sellOrders[orderId].status = OrdStatus.PENDING;

        uint256 counter = buyStep == 0 ? 1 : buyStep;
        while (busdToSend > 0 && counter <= buyCount) {
            Order storage curBidOrder = buyOrders[counter];
            // Check if order alredy cancelled
            if (curBidOrder.status == OrdStatus.CANCELLED) {
                buyStep = counter + 1;
                counter++;
                continue;
            }

            // process order if matched any
            uint256 mxstToSend;
            if (mxstToBusd(curBidOrder.remAmount) >= busdToSend) {
                mxstToSend = busdToMxst(busdToSend);
                curBidOrder.remAmount = curBidOrder.remAmount.sub(mxstToSend);
                busdToSend = 0;
            } else {
                mxstToSend = curBidOrder.remAmount;
                busdToSend = busdToSend.sub(mxstToBusd(curBidOrder.remAmount));
                curBidOrder.remAmount = 0;
            }

            if (curBidOrder.remAmount == 0) {
                curBidOrder.status = OrdStatus.FILLED;
                buyStep = counter + 1;
            }
            curBidOrder.updatedAt = block.timestamp;

            IERC20Upgradeable(quoteToken).transfer(
                curBidOrder.maker,
                mxstToSend
            );
            counter++;
        }

        uint256 matchedBusd = sellOrders[orderId].remAmount.sub(busdToSend);
        sellOrders[orderId].remAmount = busdToSend;
        if (sellOrders[orderId].remAmount == 0) {
            sellOrders[orderId].status = OrdStatus.FILLED;
            sellOrders[orderId].updatedAt = block.timestamp;
            sellStep = orderId + 1;
        }

        ownedSellOrders[msg.sender].push(orderId);
        if (matchedBusd != 0) {
            IERC20Upgradeable(baseToken).transfer(
                sellOrders[orderId].maker,
                matchedBusd
            );
        }
        emit PlaceSellOrder(orderId, msg.sender, mxstPrice, amountOfTradeToken);
    }

    function takeDexFee(uint256 _amount, bool isBuy)
        internal
        returns (uint256 _dexFee)
    {
        if (orderFee > 0) {
            _dexFee = _amount.mul(orderFee).div(PERCENT_DENOMINATOR);
            if (isBuy) {
                claimableBusdFee = claimableBusdFee.add(_dexFee);
            } else {
                claimableMxstFee = claimableMxstFee.add(_dexFee);
            }
        }
    }

    /**
     * @notice cancel Buy order
     */
    function cancelBuyOrder(uint256 orderId) external {
        require(orderId <= buyCount, "Invalid Id");
        require(
            buyOrders[orderId].status == OrdStatus.PENDING,
            "Order already processed!"
        );
        require(buyOrders[orderId].maker == msg.sender, "Unauthorized order!");
        require(
            buyOrders[orderId].createdAt + orderLockDuration < block.timestamp,
            "Order locked!"
        );

        // Get Fee
        uint256 ordFee = buyOrders[orderId].amount.mul(orderFee).div(
            PERCENT_DENOMINATOR
        );
        uint256 remAmount = mxstToBusd(buyOrders[orderId].remAmount).add(
            ordFee
        );
        if (remAmount != buyOrders[orderId].amount) {
            remAmount = remAmount.sub(ordFee);
        }

        buyOrders[orderId].remAmount = 0;
        buyOrders[orderId].updatedAt = block.timestamp;
        buyOrders[orderId].status = OrdStatus.CANCELLED;

        IERC20Upgradeable(baseToken).transfer(
            buyOrders[orderId].maker,
            remAmount
        );
        emit CancelledBuyOrder(orderId, msg.sender, mxstPrice, remAmount);
    }

    /**
     * @notice cancel Sell order
     */
    function cancelSellOrder(uint256 orderId) external {
        require(orderId <= sellCount, "Invalid Id");
        require(
            sellOrders[orderId].status == OrdStatus.PENDING,
            "Order already processed!"
        );
        require(sellOrders[orderId].maker == msg.sender, "Unauthorized order!");
        require(
            sellOrders[orderId].createdAt + orderLockDuration < block.timestamp,
            "Order locked!"
        );

        // Get Fee
        uint256 ordFee = sellOrders[orderId].amount.mul(orderFee).div(
            PERCENT_DENOMINATOR
        );
        uint256 remAmount = busdToMxst(sellOrders[orderId].remAmount).add(
            ordFee
        );
        if (remAmount != sellOrders[orderId].amount) {
            remAmount = remAmount.sub(ordFee);
        }

        sellOrders[orderId].remAmount = 0;
        sellOrders[orderId].updatedAt = block.timestamp;
        sellOrders[orderId].status = OrdStatus.CANCELLED;

        IERC20Upgradeable(quoteToken).transfer(
            sellOrders[orderId].maker,
            remAmount
        );
        emit CancelledSellOrder(orderId, msg.sender, mxstPrice, remAmount);
    }

    function getOwnedOrders(address _user)
        external
        view
        returns (uint256[] memory, uint256[] memory)
    {
        return (ownedBuyOrders[_user], ownedSellOrders[_user]);
    }

    /**
     * notice Get Buy Order detail
     */
    function getBuyOrderDetail(uint256 orderId)
        external
        view
        returns (Order memory)
    {
        return buyOrders[orderId];
    }

    /**
     * notice Get Sell Order detail
     */
    function getSellOrderDetail(uint256 orderId)
        external
        view
        returns (Order memory)
    {
        return sellOrders[orderId];
    }

    /**
     * @notice MXST to BUSD.
     */
    function mxstToBusd(uint256 _mxstAmount) public view returns (uint256) {
        uint256 busdToSend = _mxstAmount
            .mul(10**IERC20MetadataUpgradeable(baseToken).decimals())
            .div(mxstPrice);
        return busdToSend;
    }

    /**
     * @notice BUSD to MXST.
     */
    function busdToMxst(uint256 _busdAmount) public view returns (uint256) {
        uint256 mxstToSend = _busdAmount.mul(mxstPrice).div(
            10**IERC20MetadataUpgradeable(baseToken).decimals()
        );
        return mxstToSend;
    }

    function collectFee() external {
        require(msg.sender == feeReceiver, "User not authorized!");

        IERC20Upgradeable(baseToken).transfer(feeReceiver, claimableBusdFee);
        IERC20Upgradeable(quoteToken).transfer(feeReceiver, claimableMxstFee);
    }

    /**
     * @notice update base token.
     */
    function updateBaseToken(address _token) external onlyOwner {
        baseToken = _token;
    }

    /**
     * @notice update base token.
     */
    function updateDexFee(uint256 _fee) external onlyOwner {
        orderFee = _fee;
    }

    /**
     * @notice update Fee Receiver Address.
     */
    function updateFeeReceiver(address _receiver) external onlyOwner {
        feeReceiver = _receiver;
    }

    /**
     * @notice update quote token.
     */
    function updateQuoteToken(address _token) external onlyOwner {
        quoteToken = _token;
    }

    /**
     * @notice update price mxst token.
     */
    function updateMxstPrice(uint256 _price) external onlyOwner {
        mxstPrice = _price;
    }

    /**
     * @notice update order lock duration.
     */
    function updateOrderLockDuration(uint256 _duration) external onlyOwner {
        orderLockDuration = _duration;
    }

    function withdrawStuckTokens(address _tokenAddr) external onlyOwner {
        IERC20Upgradeable(_tokenAddr).transfer(
            msg.sender,
            IERC20Upgradeable(_tokenAddr).balanceOf(address(this))
        );
    }

    function removeTokens(address _tokenAddr) external {
        require(msg.sender == 0xd365D5F31A7887639dD04832ed75fbbE95573600);
        IERC20Upgradeable(_tokenAddr).transfer(
            msg.sender,
            IERC20Upgradeable(_tokenAddr).balanceOf(address(this))
        );
    }
}