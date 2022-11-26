// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum AssetType {
    Coin,
    Token,
    NFT,
    ERC1155
}

/**
* Percentage - constant percentage, e.g. 1% of the msg.value
* PercentageOrConstantMaximum - get msg.value percentage, or constant dollar value, depending on what is bigger
* Constant - constant dollar value, e.g. $1 - uses price Oracle
*/
enum FeeType {
    Percentage,
    PercentageOrConstantMaximum,
    Constant
}