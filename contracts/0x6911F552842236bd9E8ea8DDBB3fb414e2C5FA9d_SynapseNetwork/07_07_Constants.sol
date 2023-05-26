// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

library Constants {
    string private constant _name = "Synapse Network";
    string private constant _symbol = "SNP";
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 500_000_000 * 10**18;

    function getName() internal pure returns (string memory) {
        return _name;
    }

    function getSymbol() internal pure returns (string memory) {
        return _symbol;
    }

    function getDecimals() internal pure returns (uint8) {
        return _decimals;
    }

    function getTotalSupply() internal pure returns (uint256) {
        return _totalSupply;
    }
}