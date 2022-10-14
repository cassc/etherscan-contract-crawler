// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

struct SaleManagerConstructorArgs {
    uint256 price;
    uint256 maxTokensInSale;
    uint256 maxPerTransaction;
}

enum SaleState {
    OFF,
    CLAIM,
    ACTIVE
}

contract SaleManager {
    uint256 public PRICE;
    uint256 public MAX_TOKENS_IN_SALE;
    uint256 public MAX_PER_TRANSACTION;

    SaleState public saleState;
    mapping(uint256 => address) public callerByRequestId;
    mapping(address => uint256) public tokensClaimedByAddress;

    uint256 public counter;
    uint256 public supply;

    constructor(SaleManagerConstructorArgs memory _saleManagerConstructorArgs) {
        PRICE = _saleManagerConstructorArgs.price;
        MAX_TOKENS_IN_SALE = _saleManagerConstructorArgs.maxTokensInSale;
        MAX_PER_TRANSACTION = _saleManagerConstructorArgs.maxPerTransaction;
    }

    function setSaleState(SaleState _saleState) public virtual {
        saleState = _saleState;
    }
}