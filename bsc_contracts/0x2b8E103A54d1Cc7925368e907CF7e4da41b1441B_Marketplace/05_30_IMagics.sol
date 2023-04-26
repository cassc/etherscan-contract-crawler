// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './enums/TokenType.sol';

struct ItemDetails {
    address creator;
    uint256 royalty;
    TokenType mintTokenType;
}

interface IMagics {
    function itemDetails(uint256 id) external returns (ItemDetails memory);

    function getProfitAddress() external view returns (address);
}