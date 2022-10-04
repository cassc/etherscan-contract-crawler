// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "./BaseSale.sol";

contract PublicSale is BaseSale {
    struct ConstructorArgs {
        address nft;
        uint256 price;
        uint256 allocation;
        uint256 maxTokenPurchase;
        address payable treasury;
    }

    uint256 public allocation;

    constructor(ConstructorArgs memory _data)
        BaseSale(_data.nft)
    {
        _defaultPrice = _data.price;
        allocation = _data.allocation;
        maxTokenPurchase = _data.maxTokenPurchase;
        treasury = _data.treasury;
    }

    receive()
        external
        payable
        checkStatus
    {
        uint256 amount = msg.value / _defaultPrice;

        require(
            amount != 0 && amount <= maxTokenPurchase,
            "Market: invalid amount set, to much or too low"
        );
        require(allocation != 0, "SOLD");
        require(amount <= allocation, "LOW_ALLOCATION");

        allocation -= amount;
        _buy(msg.sender, amount, msg.value);
    }

    function buy(uint256 _amount)
        external
        payable
        checkStatus
        isCorrectAmount(_amount)
    {
        require(allocation != 0, "SOLD");
        require(_amount <= allocation, "LOW_ALLOCATION");
        allocation -= _amount;
        _buy(msg.sender, _amount, msg.value);
    }
}