// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OgSale is Ownable, ReentrancyGuard {
    
    modifier isOgSaleActive() {
        require(isOgSaleActivated(), "OGsale Not Active!");
        _;
    }

    uint256 public ogSaleStart;
    uint256 public ogSaleEnd;
    uint256 public totalSupplyOgSale;

    constructor(uint256 _ogSaleStart, uint256 _ogSaleEnd) {
        ogSaleStart = _ogSaleStart;
        ogSaleEnd = _ogSaleEnd;
    }

    function isOgSaleActivated() public view returns (bool) {
        return  ogSaleStart > 0 &&
                ogSaleEnd > 0 &&
                block.timestamp >= ogSaleStart &&
                block.timestamp <= ogSaleEnd;
    }

    function setTimeStampOgSale(uint256 _ogSaleStart, uint256 _ogSaleEnd) external onlyOwner nonReentrant{
        ogSaleStart = _ogSaleStart;
        ogSaleEnd = _ogSaleEnd;
    }

}