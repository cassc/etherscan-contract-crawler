//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./util/SafeMath.sol";
import "./util/Math.sol";
import "./util/SafeERC20.sol";
import "./util/IERC20.sol";
import "./util/IERC721Receiver.sol";
import "./util/IERC721.sol";
import "./util/Counters.sol";
import "./util/Ownable.sol";
import "./util/EnumerableSet.sol";
import "./IMarket.sol";
import "./util/ERC1155Holder.sol";
import "./util/ERC721Holder.sol";
import "./util/IERC1155.sol";

contract XmultiverseNFTMarket is IMarket, Ownable, ERC1155Holder, ERC721Holder {
    using SafeMath for uint256;
    using Math for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public tradeFeeRate = 10; // 0-200, default 10
    uint256 public constant rateBase = 1000; // base is always 1000

    using Counters for Counters.Counter;
    Counters.Counter private _orderCounter;
    mapping(uint256 => Order) public orderStorage;
    mapping(uint256 => BidInfo) public bidStorage;
    mapping(address => EnumerableSet.UintSet) private _orderIds;
    mapping(address => mapping(uint256 => EnumerableSet.UintSet))
        private _nftOrderIds;

    /********** mutable functions **********/

    function setTradeFeeRate(uint256 newTradeFeeRate) external onlyOwner {
        require(tradeFeeRate <= 200, "Trade fee rate exceed limit");
        tradeFeeRate = newTradeFeeRate;
    }

    function createOrder(
        OrderType orderType,
        NFTType nftType,
        address nftToken,
        uint256 tokenId,
        uint256 tokenAmount,
        address token,
        uint256 price,
        uint256 timeLimit,
        uint256 changeRate,
        uint256 minPrice
    ) external override returns (uint256) {
        require(price > 0, "Price invalid");
        require(timeLimit > 0, "TimeLimit invalid");
        // require(orderType >= 1 && orderType <= 3, "OrderType invalid");
        // verify changeRate and minPrice
        if (orderType == OrderType.Buy || orderType == OrderType.Sell) {
            changeRate = 0;
            minPrice = 0;
        } else if (orderType == OrderType.Auction) {
            require(changeRate > 0, "ChangeRate invalid");
            minPrice = 0;
        } else if (orderType == OrderType.DutchAuction) {
            require(changeRate > 0, "ChangeRate invalid");
            require(minPrice > 0 && minPrice < price, "MinPrice invalid");
        }

        _orderCounter.increment();
        uint256 orderId = _orderCounter.current();
        NftInfo memory nftInfo = NftInfo({
            nftType: nftType,
            nftToken: nftToken,
            tokenId: tokenId,
            tokenAmount: tokenAmount
        });
        Order memory order = Order({
            id: orderId,
            orderType: orderType,
            orderOwner: msg.sender,
            nftInfo: nftInfo,
            token: token,
            price: price,
            startTime: block.timestamp,
            endTime: block.timestamp.add(timeLimit),
            changeRate: changeRate,
            minPrice: minPrice
        });

        // token amount is always 1 for erc721
        if (nftType == NFTType.ERC721) {
            order.nftInfo.tokenAmount = 1;
        }
        // lock asset
        if (orderType == OrderType.Buy) {
            _safeTransferERC20(
                order.token,
                msg.sender,
                address(this),
                order.price
            );
        } else if (nftType == NFTType.ERC721) {
            _safeTransferERC721(
                order.nftInfo.nftToken,
                msg.sender,
                address(this),
                order.nftInfo.tokenId
            );
        } else {
            _safeTransferERC1155(
                order.nftInfo.nftToken,
                msg.sender,
                address(this),
                order.nftInfo.tokenId,
                order.nftInfo.tokenAmount
            );
        }

        emit CreateOrder(
            order.id,
            uint256(order.orderType),
            order.orderOwner,
            order
        );
        _addOrder(order);
        return order.id;
    }

    function _safeTransferERC20(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 balance = IERC20(token).balanceOf(from);
        require(balance >= amount, "Balance insufficient");
        if (from == address(this)) {
            IERC20(token).safeTransfer(to, amount);
        } else {
            IERC20(token).safeTransferFrom(from, to, amount);
        }
    }

    function _safeTransferERC721(
        address nftToken,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        address nftOwner = IERC721(nftToken).ownerOf(tokenId);
        require(from == nftOwner, "Nft owner invalid");
        IERC721(nftToken).safeTransferFrom(from, to, tokenId);
    }

    function _safeTransferERC1155(
        address nftToken,
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) internal {
        uint256 balance = IERC1155(nftToken).balanceOf(from, id);
        require(balance >= amount, "ERC1155 balance insufficient");
        IERC1155(nftToken).safeTransferFrom(from, to, id, amount, "");
    }

    function _addOrder(Order memory order) private {
        orderStorage[order.id] = order;
        _orderIds[order.orderOwner].add(order.id);
        _nftOrderIds[order.nftInfo.nftToken][order.nftInfo.tokenId].add(
            order.id
        );
    }

    function _deleteOrder(Order memory order) private {
        delete orderStorage[order.id];
        _orderIds[order.orderOwner].remove(order.id);
        _nftOrderIds[order.nftInfo.nftToken][order.nftInfo.tokenId].remove(
            order.id
        );
    }

    function changeOrder(
        uint256 orderId,
        uint256 price,
        uint256 timeLimit
    ) external override {
        Order memory order = orderStorage[orderId];
        require(order.id > 0, "Order not exist");
        require(order.orderOwner == msg.sender, "Order owner not match");
        require(price > 0, "Price invalid");
        require(timeLimit > 0, "TimeLimit invalid");
        require(
            order.orderType != OrderType.Auction &&
                order.orderType != OrderType.DutchAuction,
            "Auction or DutchAuction change is not allowed"
        );

        // change locked token
        if (order.orderType == OrderType.Buy && order.price != price) {
            if (price > order.price) {
                _safeTransferERC20(
                    order.token,
                    msg.sender,
                    address(this),
                    price.sub(order.price)
                );
            } else {
                _safeTransferERC20(
                    order.token,
                    address(this),
                    msg.sender,
                    order.price.sub(price)
                );
            }
        }

        order.price = price;
        order.endTime = block.timestamp.add(timeLimit);
        emit ChangeOrder(
            order.id,
            uint256(order.orderType),
            order.orderOwner,
            order.token,
            order.price,
            order.startTime,
            order.endTime
        );
        orderStorage[order.id] = order;
    }

    function cancelOrder(uint256 orderId) external override {
        Order memory order = orderStorage[orderId];
        require(order.id > 0, "Order not exist");
        require(order.orderOwner == msg.sender, "Order owner not match");
        if (order.orderType == OrderType.Auction) {
            // check bid info
            BidInfo memory bidInfo = bidStorage[orderId];
            require(bidInfo.price == 0, "Bid should be Null");
        }
        if (order.orderType == OrderType.Buy) {
            // unlock token
            _safeTransferERC20(
                order.token,
                address(this),
                order.orderOwner,
                order.price
            );
        } else {
            // unlock nft
            if (order.nftInfo.nftType == NFTType.ERC721) {
                _safeTransferERC721(
                    order.nftInfo.nftToken,
                    address(this),
                    order.orderOwner,
                    order.nftInfo.tokenId
                );
            } else {
                _safeTransferERC1155(
                    order.nftInfo.nftToken,
                    address(this),
                    order.orderOwner,
                    order.nftInfo.tokenId,
                    order.nftInfo.tokenAmount
                );
            }
        }

        emit CancelOrder(
            order.id,
            uint256(order.orderType),
            order.orderOwner,
            order.nftInfo.nftToken,
            order.nftInfo.tokenId
        );
        _deleteOrder(order);
    }

    function fulfillOrder(uint256 orderId, uint256 price) external override {
        Order memory order = orderStorage[orderId];
        require(order.id > 0, "Order not exist");
        require(
            order.price == price ||
                (order.orderType == OrderType.DutchAuction &&
                    price == getDutchPrice(order.id)),
            "Price not match"
        );
        require(block.timestamp <= order.endTime, "Order expired");
        require(order.orderType != OrderType.Auction, "OrderType invalid");
        // use new price for Dutch Auction
        order.price = price;
        if (
            order.orderType == OrderType.Sell ||
            order.orderType == OrderType.DutchAuction
        ) {
            _payToken(order);
        } else if (order.orderType == OrderType.Buy) {
            _payNft(order);
        }

        emit CompleteOrder(
            order.id,
            uint256(order.orderType),
            order.orderOwner,
            msg.sender,
            order
        );
        _deleteOrder(order);
    }

    function _payToken(Order memory order) internal {
        uint256 fee = order.price.mul(tradeFeeRate).div(rateBase);
        _safeTransferERC20(order.token, msg.sender, owner(), fee);
        _safeTransferERC20(
            order.token,
            msg.sender,
            order.orderOwner,
            order.price.sub(fee)
        );
        if (order.nftInfo.nftType == NFTType.ERC721) {
            _safeTransferERC721(
                order.nftInfo.nftToken,
                address(this),
                msg.sender,
                order.nftInfo.tokenId
            );
        } else {
            _safeTransferERC1155(
                order.nftInfo.nftToken,
                address(this),
                msg.sender,
                order.nftInfo.tokenId,
                order.nftInfo.tokenAmount
            );
        }
    }

    function _payNft(Order memory order) internal {
        if (order.nftInfo.nftType == NFTType.ERC721) {
            _safeTransferERC721(
                order.nftInfo.nftToken,
                msg.sender,
                order.orderOwner,
                order.nftInfo.tokenId
            );
        } else {
            _safeTransferERC1155(
                order.nftInfo.nftToken,
                msg.sender,
                order.orderOwner,
                order.nftInfo.tokenId,
                order.nftInfo.tokenAmount
            );
        }
        uint256 fee = order.price.mul(tradeFeeRate).div(rateBase);
        _safeTransferERC20(order.token, address(this), owner(), fee);
        _safeTransferERC20(
            order.token,
            address(this),
            order.orderOwner,
            order.price.sub(fee)
        );
    }

    function bid(uint256 orderId, uint256 price) external override {
        Order memory order = orderStorage[orderId];
        require(order.id > 0, "Order not exist");
        require(price >= order.price, "Price needs to exceed reserve price");
        require(block.timestamp <= order.endTime, "Order expired");
        require(order.orderType == OrderType.Auction, "OrderType invalid");
        BidInfo memory currentBid = bidStorage[orderId];
        if (currentBid.price > 0) {
            require(
                price >=
                    currentBid.price.add(
                        currentBid.price.mul(order.changeRate).div(rateBase)
                    ),
                "Bid price low"
            );
            // refund current bid
            _safeTransferERC20(
                order.token,
                address(this),
                currentBid.bidder,
                currentBid.price
            );
        }

        BidInfo memory bidInfo = BidInfo({bidder: msg.sender, price: price});
        _safeTransferERC20(
            order.token,
            bidInfo.bidder,
            address(this),
            bidInfo.price
        );

        emit Bid(
            order.id,
            uint256(order.orderType),
            order.orderOwner,
            msg.sender,
            block.timestamp,
            order.token,
            bidInfo.price
        );
        bidStorage[order.id] = bidInfo;
    }

    function claim(uint256 orderId) external override {
        Order memory order = orderStorage[orderId];
        require(order.id > 0, "Order not exist");
        require(block.timestamp > order.endTime, "Order is in auction time");
        require(order.orderType == OrderType.Auction, "OrderType invalid");
        BidInfo memory currentBid = bidStorage[orderId];
        require(currentBid.price > 0, "Bid not exist");
        require(
            msg.sender == order.orderOwner || msg.sender == currentBid.bidder,
            "Only order owner or bidder can claim"
        );

        uint256 fee = currentBid.price.mul(tradeFeeRate).div(rateBase);
        _safeTransferERC20(order.token, address(this), owner(), fee);
        _safeTransferERC20(
            order.token,
            address(this),
            order.orderOwner,
            currentBid.price.sub(fee)
        );
        _safeTransferERC721(
            order.nftInfo.nftToken,
            address(this),
            currentBid.bidder,
            order.nftInfo.tokenId
        );
        order.price = currentBid.price;
        emit CompleteOrder(
            order.id,
            uint256(order.orderType),
            order.orderOwner,
            msg.sender,
            order
        );
        delete bidStorage[order.id];
        _deleteOrder(order);
    }

    /********** view functions **********/

    function name() external pure override returns (string memory) {
        return "SAIYA NFT Market";
    }

    function getTradeFeeRate() external view override returns (uint256) {
        return tradeFeeRate;
    }

    function getOrder(uint256 orderId)
        external
        view
        override
        returns (Order memory)
    {
        return orderStorage[orderId];
    }

    function getDutchPrice(uint256 orderId)
        public
        view
        override
        returns (uint256)
    {
        Order memory order = orderStorage[orderId];
        require(order.id > 0, "Order not exist");
        require(
            order.orderType == OrderType.DutchAuction,
            "Order type invalid"
        );
        uint256 oneHour = 1 hours;
        uint256 decreasePrice = order
            .price
            .mul(order.changeRate)
            .mul(block.timestamp.sub(order.startTime).div(oneHour))
            .div(rateBase);
        if (decreasePrice.add(order.minPrice) > order.price) {
            return order.minPrice;
        }
        return order.price.sub(decreasePrice);
    }

    function getBidInfo(uint256 orderId)
        external
        view
        override
        returns (BidInfo memory)
    {
        return bidStorage[orderId];
    }

    function getOrdersByOwner(address orderOwner)
        external
        view
        override
        returns (Order[] memory)
    {
        uint256 length = _orderIds[orderOwner].length();
        Order[] memory list = new Order[](length);
        for (uint256 i = 0; i < length; i++) {
            list[i] = orderStorage[_orderIds[orderOwner].at(i)];
        }
        return list;
    }

    function getOrdersByNft(address nftToken, uint256 tokenId)
        external
        view
        override
        returns (Order[] memory)
    {
        uint256 length = _nftOrderIds[nftToken][tokenId].length();
        Order[] memory list = new Order[](length);
        for (uint256 i = 0; i < length; i++) {
            list[i] = orderStorage[_nftOrderIds[nftToken][tokenId].at(i)];
        }
        return list;
    }
}