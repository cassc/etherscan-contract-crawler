// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface ICryptoFoxesShopStruct {

    struct Product {
        uint256 price;
        uint256 start;
        uint256 end;
        uint256 maxPerWallet; // 0 for infinity
        uint256 quantityMax; // 0 for infinity
        bool enable;
        bool isValid;
    }

}