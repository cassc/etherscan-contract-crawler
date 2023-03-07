// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./AdminContract.sol";
import "./UserDefined1155.sol";

contract MyNFTStorage is
    Initializable,
    ERC1155HolderUpgradeable,
    ReentrancyGuardUpgradeable
{
    uint private constant EVENT_SELL = 1;
    uint private constant EVENT_BUY = 2;
    uint private constant EVENT_CANCEL = 3;
    UserDefined1155 minter;
    AdminConsole admin;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet private orderSet;
    Counters.Counter private _orderIdTracker;
    Counters.Counter private _orderIndexerTracker;
    using SafeMath for uint256;

    event ListedForSale(
        uint256 indexed uuidTransaction,
        uint256 indexed orderIndexer,
        uint256 indexed orderId,
        uint eventType
    );

    event CancelOrder(uint256 indexed uuidTransaction, uint eventType);

    event BuyOrder(
        uint256 indexed uuidTransaction,
        address indexed buyer,
        uint eventType
    );

    struct OrderDetail {
        uint tokenId;
        uint256 indexer;
        address owner;
        address nftAddress;
        uint quantity;
        address tokenPayment;
        uint256 price;
        uint feePercent;
        uint createdAt;
        uint updatedAt;
        uint256 uuidTransaction;
    }

    struct OrderSoldHistory {
        address buyer;
        OrderDetail orderDetail;
        uint createdAt;
    }

    // ============MAPPING==============
    mapping(uint => OrderDetail) listOrderDetail; // orderId -> OrderDetail
    OrderSoldHistory[] listOrderSold;

    mapping(address => uint[]) listOrderOwnerByAddress;

    function initialize(address _admin) public initializer {
        admin = AdminConsole(_admin);
    }

    function createOrder(
        address nftAddress,
        uint256 tokenId,
        uint256 tokenPrice,
        uint256 quantity,
        address tokenPayment,
        uint256 uuidTransaction
    ) public {
        address account = msg.sender;
        minter = UserDefined1155(nftAddress);
        uint tokensHeld = minter.balanceOf(account, tokenId);

        require(
            tokensHeld > 0,
            "This user does not have any units of this token available for listing!"
        );
        require(
            quantity <= tokensHeld,
            "You cannot list this units of this token, try reducing the quantity!"
        );

        uint orderId = _orderIndexerTracker.current();

        OrderDetail storage myOrder = listOrderDetail[orderId];
        myOrder.tokenId = tokenId;
        myOrder.indexer = orderId;
        myOrder.nftAddress = nftAddress;
        myOrder.quantity = quantity;
        myOrder.owner = payable(account);
        myOrder.price = tokenPrice;
        myOrder.tokenPayment = tokenPayment;
        myOrder.feePercent = admin.getFeePercent();
        myOrder.createdAt = block.timestamp;
        myOrder.uuidTransaction = uuidTransaction;

        minter.safeTransferFrom(account, address(this), tokenId, quantity, "");
        _orderIndexerTracker.increment();
        EnumerableSet.add(orderSet, orderId);

        emit ListedForSale(uuidTransaction, orderId, orderId, EVENT_SELL);
    }

    function cancelOrder(uint orderId) public {
        OrderDetail storage myOrder = listOrderDetail[orderId];
        require(myOrder.owner == msg.sender, "You not owner this order");
        minter = UserDefined1155(myOrder.nftAddress);
        minter.safeTransferFrom(
            address(this),
            myOrder.owner,
            myOrder.tokenId,
            myOrder.quantity,
            ""
        );

        EnumerableSet.remove(orderSet, orderId);
        emit CancelOrder(myOrder.uuidTransaction, EVENT_CANCEL);
    }

    function buyOrder(uint orderId) public payable nonReentrant {
        OrderDetail memory order = listOrderDetail[orderId];
        require(
            order.owner != msg.sender,
            "Cannot buy order created by yourself"
        );
        require(order.price > 0, "Order price must be positive");

        uint256 orderPrice = order.price;
        uint256 fee = SafeMath.div(
            SafeMath.mul(orderPrice, order.feePercent),
            10000
        );
        uint256 realOrderPrice = SafeMath.sub(orderPrice, fee);

        uint256 royaltyShared = 0;
        bool isNativePayment = false;
        IERC20 payment;

        // Checker balance msg.sender
        if (order.tokenPayment == address(0x0)) {
            isNativePayment = true;
        } else payment = IERC20(order.tokenPayment);

        if (!isNativePayment) {
            require(
                payment.allowance(msg.sender, address(this)) >= orderPrice,
                "Insufficient allowance for proccessing buy this order"
            );
            require(
                payment.balanceOf(msg.sender) >= orderPrice,
                "Total price exceeded balance"
            );
            if (fee > 0)
                payment.transferFrom(
                    msg.sender,
                    address(admin.getFeeAccount()),
                    fee
                );
        } else {
            require(msg.value >= orderPrice, "Total price exceeded balance");
            if (fee > 0) payable(address(admin.getFeeAccount())).transfer(fee);
        }

        // Share royalty
        minter = UserDefined1155(order.nftAddress);
        LibPart.Part[] memory royalties = minter.getRaribleV2Royalties(
            order.tokenId
        );

        for (uint i = 0; i < royalties.length; i++) {
            if (
                royalties[i].account == address(0x0) ||
                royalties[i].value <= 0 ||
                royalties[i].account == msg.sender ||
                royalties[i].account == order.owner
            ) continue;

            uint256 shared = SafeMath.div(
                SafeMath.mul(realOrderPrice, royalties[i].value),
                10000
            );
            royaltyShared = SafeMath.add(royaltyShared, shared);
            if (!isNativePayment) {
                payment.transferFrom(
                    msg.sender,
                    address(royalties[i].account),
                    shared
                );
            } else {
                payable(address(royalties[i].account)).transfer(shared);
            }
        }

        if (!isNativePayment) {
            payment.transferFrom(
                msg.sender,
                address(order.owner),
                SafeMath.sub(realOrderPrice, royaltyShared)
            );
        } else {
            payable(address(order.owner)).transfer(
                SafeMath.sub(realOrderPrice, royaltyShared)
            );
        }

        OrderSoldHistory memory orderSold;
        orderSold.orderDetail = order;
        orderSold.buyer = msg.sender;
        orderSold.createdAt = block.timestamp;
        listOrderSold.push(orderSold);

        minter.safeTransferFrom(
            address(this),
            msg.sender,
            order.tokenId,
            order.quantity,
            ""
        );

        EnumerableSet.remove(orderSet, orderId);

        emit BuyOrder(order.uuidTransaction, msg.sender, EVENT_BUY);
    }

    function getOrders() public view returns (uint[] memory) {
        return EnumerableSet.values(orderSet);
    }

    function getOrderDetail(
        uint orderId
    ) public view returns (OrderDetail memory) {
        return listOrderDetail[orderId];
    }

    function getOrdersSold() public view returns (OrderSoldHistory[] memory) {
        return listOrderSold;
    }
}