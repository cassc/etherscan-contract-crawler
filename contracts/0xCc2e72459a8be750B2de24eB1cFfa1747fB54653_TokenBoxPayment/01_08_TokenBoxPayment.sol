// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenBoxPayment is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event OrderPaid(
        address buyer,
        uint256 boxId,
        uint256 quantity,
        uint256 orderId
    );

    struct Box {
        uint256 id;
        uint256 price;
        bool isOnSale;
    }

    IERC20 private immutable paymentToken;
    mapping(uint256 => Box) public boxes;
    mapping(uint256 => bool) public paidOrders;

    constructor(IERC20 _paymentToken) {
        paymentToken = _paymentToken;
    }

    function setBox(
        uint256 _boxId,
        uint256 _price,
        bool _isOnSale
    ) external onlyOwner {
        boxes[_boxId] = Box(_boxId, _price, _isOnSale);
    }

    function buy(
        uint256 _boxId,
        uint256 _quantity,
        uint256 _orderId
    ) external nonReentrant {
        require(_quantity > 0, "TokenBoxPayment: invalid quantity");
        require(!paidOrders[_orderId], "TokenBoxPayment: order already paid");

        Box storage box = boxes[_boxId];
        require(box.isOnSale, "TokenBoxPayment: box is not on sale");

        paymentToken.safeTransferFrom(
            msg.sender,
            address(this),
            box.price * _quantity
        );
        paidOrders[_orderId] = true;

        emit OrderPaid(msg.sender, _boxId, _quantity, _orderId);
    }

    function withdraw() external onlyOwner {
        paymentToken.safeTransfer(
            msg.sender,
            paymentToken.balanceOf(address(this))
        );
    }
}