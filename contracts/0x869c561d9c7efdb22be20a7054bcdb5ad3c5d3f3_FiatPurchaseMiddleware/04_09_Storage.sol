// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "lib/openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPresalePurchases.sol";

contract Storage {
    IERC20 public usdToken;

    IERC20 public saleToken;

    IPresalePurchases public presale;

    uint256 public purchaseSum;

    bool public _initialized;

    mapping(address => uint256) public _purchasedTokens;

    mapping(address => bool) public hasClaimed;

    mapping(string => bytes32) public varStorage;
}