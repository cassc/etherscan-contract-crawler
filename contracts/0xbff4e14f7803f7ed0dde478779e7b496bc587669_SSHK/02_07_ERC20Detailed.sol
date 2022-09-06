// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "./ERC20.sol";

contract ERC20Detailed is ERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply
    )  {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _mint(msg.sender, totalSupply);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }
}