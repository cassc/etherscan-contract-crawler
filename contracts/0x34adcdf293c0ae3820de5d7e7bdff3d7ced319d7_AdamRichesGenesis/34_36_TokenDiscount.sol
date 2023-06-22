// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

struct TokenDiscountConfig {
    uint256 price;
    uint256 supply;
    bool active;
}
struct TokenDiscountInput {
    IERC721 tokenAddress;
    TokenDiscountConfig config;
}
struct TokenDiscountOutput {
    IERC721 tokenAddress;
    string name;
    string symbol;
    uint256 usedAmount;
    TokenDiscountConfig config;
}