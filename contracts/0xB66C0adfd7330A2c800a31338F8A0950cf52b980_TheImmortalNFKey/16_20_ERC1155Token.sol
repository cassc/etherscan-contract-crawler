// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @dev Adding token name and symbol to ERC1155
 */
abstract contract ERC1155Token {
    // The token name
    string _name;

    // The token symbol
    string _symbol;

    /**
     * @dev Returns the token collection name.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }
}