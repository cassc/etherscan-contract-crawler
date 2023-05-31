// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import {OrderType, AssetType} from "./Enums.sol";

struct Asset {
    AssetType assetType;
    address collection;
    uint256 id;
    uint256 amount;
}

struct Order {
    Asset[] bid;
    Asset[] ask;
    uint256 totalAmount;
    uint256 amount;
    bytes32 root;
    bytes rootSign;
    address payable signer;
    uint256 creationDate;
    uint256 expirationDate;
    bytes32[] proof;
    bool askAny;
    bool bidAny;
    OrderType orderType;
}