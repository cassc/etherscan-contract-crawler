// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../../access/TXLimiter.sol";
import "../../access/PurchaseLimiter.sol";
import "../ERC721Collection.sol";

abstract contract ERC721Sale is Ownable, ERC721Collection, PurchaseLimiter {
    using SafeMath for uint256;

    bool public saleIsActive = false;
    uint256 public salePrice = 77 * 1e15; // 0.077 ETH


    function setSaleState(bool state) public onlyOwner {
        saleIsActive = state;
    }

    function setSalePrice(uint256 price) public onlyOwner {
        require(price > 0, "InvaliSalePrice");
        salePrice = price;
    }

    function mintSale(uint256 quantity) public payable {
        address to = _msgSender();

        require(saleIsActive, "SaleNotActive");
        require(salePrice.mul(quantity) <= msg.value, "IncorrectSaleValue");

        addSalePurchaseFor(to, quantity);

        mint(to, quantity);
    }
}