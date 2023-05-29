// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICryptoFoxesShopStruct.sol";

// @author: miinded.com

interface ICryptoFoxesShopProducts is ICryptoFoxesShopStruct {

    function getProducts() external view returns(Product[] memory);
    function getProduct(string calldata _slug) external view returns(Product memory);
}