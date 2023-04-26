// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RareboardSacrificeMintDiscount, SacrificeMintDiscount} from "./erc721/sacrifice/RareboardSacrificeMintDiscount.sol";

interface IToken {
    function setPrice(uint256 _price) external;
    function price() external view returns (uint256);
}

contract KreepyKrittersSacrificeMintDiscount is
    RareboardSacrificeMintDiscount
{
    constructor() SacrificeMintDiscount(0xEb37D7B4C0b2A1f6bC826FA32b284b8D1796354c) {}

    function _setPrice(address, uint256 _value) internal virtual override {
        IToken(token).setPrice(_value);
    }

    function _getPrice(address) internal virtual override view returns (uint256) {
        return IToken(token).price();
    }
}