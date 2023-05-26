// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library Constants {
    string private constant _name = "CARD.STARTER";
    string private constant _symbol = "CARDS";
    uint8 private constant _decimals = 18;
    address private constant _tokenOwner = 0x77Eb3adc0E15e0E1f447776C2E19657916406fc0;

    function getName() internal pure returns (string memory) {
        return _name;
    }

    function getSymbol() internal pure returns (string memory) {
        return _symbol;
    }

    function getDecimals() internal pure returns (uint8) {
        return _decimals;
    }

    function getTokenOwner() internal pure returns (address) {
        return _tokenOwner;
    }

}