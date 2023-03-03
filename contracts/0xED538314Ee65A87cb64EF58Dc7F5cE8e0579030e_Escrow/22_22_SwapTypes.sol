// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SwapTypes {
    struct Intent {
        address payable maker;
        address payable taker;
        uint256 beginTime;
        uint256 endTime;
        uint256 makerValue;
        uint256 takerValue;
        uint256 makerFee;
        SwapStatus status;
    }

    enum SwapStatus {
        Opened,
        Closed,
        Cancelled
    }

    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }

    struct Assets {
        TokenType typ;
        address token;
        uint256[] tokenId;
        uint256[] balance;
        bytes data;
    }
}