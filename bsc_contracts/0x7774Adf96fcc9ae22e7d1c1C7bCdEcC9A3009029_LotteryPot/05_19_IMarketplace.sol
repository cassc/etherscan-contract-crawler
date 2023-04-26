// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './enums/TokenType.sol';

struct LastPurchase {
    uint256 price;
    TokenType tokenType;
}

interface IMarketplace {
    function getLastPurchaseDetails(
        address buyer,
        uint256 nftId
    ) external view returns (LastPurchase memory);

    function tokenToEther(
        uint256 value,
        TokenType tokenType
    ) external view returns (uint256);

    function owner() external view returns (address);

    function bridgeAdmin() external view returns (address);
}