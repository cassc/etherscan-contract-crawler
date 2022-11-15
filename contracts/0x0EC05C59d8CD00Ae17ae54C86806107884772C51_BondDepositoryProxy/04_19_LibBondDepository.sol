// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title LibBondDepository
library LibBondDepository
{
     // Info about each type of market
    struct Market {
        address quoteToken;  //token to accept as payment
        uint256 capacity;   //remain sale volume
        uint256 endSaleTime;    //saleEndTime
        uint256 maxPayout;  // 한 tx에 살수 있는 물량
        uint256 tosPrice;
    }

}