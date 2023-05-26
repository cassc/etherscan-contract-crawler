// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract PurchaseLimiter is Ownable {
    using SafeMath for uint256;

    struct Purchase {
        uint256 presale;
        uint256 sale;
    }
    
    mapping(address => Purchase) private purchases;
    uint256 public maxPresalePurchase = 5;
    uint256 public maxSalePurchase = 10;

    function setMaxPurchase(uint256 presaleMax, uint256 saleMax) public onlyOwner {
        maxPresalePurchase = presaleMax;
        maxSalePurchase = saleMax;
    }

    function addPresalePurchaseFor(address to, uint256 quantity) internal {
        require(purchases[to].presale.add(quantity) <= maxPresalePurchase, "MaxPurchaseExeeded");
        purchases[to].presale += quantity;
    }

    function addSalePurchaseFor(address to, uint256 quantity) internal {
        require(purchases[to].sale.add(quantity) <= maxSalePurchase, "MaxPurchaseExeeded");
        purchases[to].sale += quantity;
    }
}