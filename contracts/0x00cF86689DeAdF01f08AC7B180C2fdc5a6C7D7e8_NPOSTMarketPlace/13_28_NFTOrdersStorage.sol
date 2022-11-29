// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract NFTOrdersStorage
{

////////////////////////////////////////// initialize

    function __init_NFTOrdersStorage(
    ) internal {
        ordersCount = 0;
    }

////////////////////////////////////////// fields definition

    struct OrderInfo {
        uint256 orderId;
        address receivePaymentAccount;
        address seller;
        address buyer;
        uint256 priceInETH;
        uint256 fee;
        address tokenAddress;
        uint256 tokenId;
        uint256 createdAt;
        uint256 deadline;
        bool isOpen;
    }

    uint256 internal ordersCount;
    // orderId => OrderInfo
    mapping (uint256 => OrderInfo) internal orders;

    // AccountSeller address => orderId
    mapping (address => uint256[]) internal sellerOrders;
    // AccountBuyer address => orderId
    mapping (address => uint256[]) internal buyersOrders;

    /** see https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps */
    uint256[46] private __gap;

////////////////////////////////////////// modifiers

    modifier orderIsOpen(uint256 _orderId) {
        require(orders[_orderId].seller != address(0), 'order not exists');
        require(orders[_orderId].isOpen, 'order is closed');
        _;
    }

////////////////////////////////////////// view methods

    function __getOrders(uint256[] storage orderIds)
        internal
        view
        returns (OrderInfo[] memory)
    {
        OrderInfo[] memory ordersToShow = new OrderInfo[](orderIds.length);
        for (uint256 i = 0; i < orderIds.length; ++i) {
            ordersToShow[i] = orders[orderIds[i]];
        }

        return ordersToShow;
    }

    function _getSellerOrders(address account)
        internal
        view
        returns (OrderInfo[] memory)
    {
        return __getOrders(sellerOrders[account]);
    }

    function _getOpenSellerOrders(address account)
        internal
        view
        returns (OrderInfo[] memory)
    {
        uint256[] storage orderIds = sellerOrders[account];

        uint256 count = 0;
        for (uint256 i = 0; i < orderIds.length; ++i) {
            if (
                orders[orderIds[i]].isOpen
            ) {
                ++count;
            }
        }

        OrderInfo[] memory ordersToShow = new OrderInfo[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < orderIds.length; ++i) {
            if (orders[orderIds[i]].isOpen) {
                ordersToShow[j] = orders[orderIds[i]];
                ++j;
            }
        }

        return ordersToShow;
    }

    function _getBuyerOrders(address account)
        internal
        view
        returns (OrderInfo[] memory)
    {
        return __getOrders(buyersOrders[account]);
    }

    function _getOpenBuyerOrders(address account)
        internal
        view
        returns (OrderInfo[] memory)
    {
        uint256[] storage orderIds = buyersOrders[account];

        uint256 count = 0;
        for (uint256 i = 0; i < orderIds.length; ++i) {
            if (
                orders[orderIds[i]].isOpen &&
                orders[orderIds[i]].deadline > block.timestamp
            ) {
                ++count;
            }
        }

        OrderInfo[] memory ordersToShow = new OrderInfo[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < orderIds.length; ++i) {
            if (
                orders[orderIds[i]].isOpen &&
                orders[orderIds[i]].deadline > block.timestamp
            ) {
                ordersToShow[j] = orders[orderIds[i]];
                ++j;
            }
        }

        return ordersToShow;
    }

////////////////////////////////////////// write methods

    function _createOrder(
        address _receivePaymentAccount,
        address _seller,
        address _buyer,
        uint256 _priceInETH,
        uint256 _fee,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _deadline
    )
        internal
        returns(OrderInfo storage)
    {
        require(_deadline > block.timestamp, '_createOrder: deadline time is over');
        uint256 orderId = ordersCount;
        ++ordersCount;

        OrderInfo storage order = orders[orderId];

        order.orderId = orderId;
        order.receivePaymentAccount = _receivePaymentAccount == address(0) ? _seller : _receivePaymentAccount;
        order.seller = _seller;
        order.buyer = _buyer;
        order.priceInETH = _priceInETH;
        order.fee = _fee;
        order.tokenAddress = _tokenAddress;
        order.tokenId = _tokenId;
        order.createdAt = block.timestamp;
        order.deadline = _deadline;
        order.isOpen = true;

        sellerOrders[order.seller].push(orderId);
        buyersOrders[order.buyer].push(orderId);

        return order;
    }

    function _tryExecuteOrder(
        uint256 orderId,
        address buyer
    )
        internal
        orderIsOpen(orderId)
        returns(OrderInfo storage)
    {
        OrderInfo storage order = orders[orderId];
        require(order.buyer == buyer || order.buyer == address(0), 'executeOrder: buyer should be same');
        require(order.deadline > block.timestamp, 'executeOrder: time is over');

        if (order.buyer == address(0)) {
            order.buyer == buyer;
            buyersOrders[order.buyer].push(orderId);
        }

        order.isOpen = false;
        return order;
    }

    function _tryRedeemNftFromOrder(
        uint256 orderId,
        address seller
    )
        internal
        orderIsOpen(orderId)
        returns(OrderInfo storage)
    {
        OrderInfo storage order = orders[orderId];
        require(order.seller == seller, '_redeemNftFromOrder: seller should be same');
        require(order.deadline < block.timestamp, '_redeemNftFromOrder: not yet time');

        order.isOpen = false;
        return order;
    }

}